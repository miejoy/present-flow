//
//  File.swift
//  
//
//  Created by 黄磊 on 2022/9/19.
//

import Foundation
import DataFlow
import ViewFlow

enum PresentReducer {
    
    static func reducer(_ state: inout PresentState, _ action: PresentAction) {
        switch action.action {
        case .present(let presentAction):
            reducerPresentAction(&state, presentAction)
        case .dismiss(let dismissAction):
            reducerDismissAction(&state, dismissAction)
        case .freeze(let freezeAction):
            reducerFreezeAction(&state, freezeAction)
        case .inner(let innerAction):
            reducerInnerAction(&state, innerAction)
        }
    }
    
    // MARK: - Present
    
    static func reducerPresentAction(_ state: inout PresentState, _ action: PresentAction.InnerPresentAction) {
        var notFoundError: TargetRouteNotFound? = nil
        let baseOnLevel = getTargetLevel(on: state, action.baseOnLevel, &notFoundError)
        if let notFoundError = notFoundError {
            PresentMonitor.shared.record(event: .presentFailed(action.route, notFoundError))
            return
        }
        
        var viewMaker = action.viewMaker
        if !viewMaker.canMakeView(on: state.sceneId) {
            PresentMonitor.shared.record(event: .presentFailedCannotMakeView(action.route))
            return
        }
        var innerPresentState = InnerPresentState(level: baseOnLevel + 1,
                                                  route: action.route,
                                                  navigationState: action.navigationState,
                                                  viewMaker: viewMaker)
        innerPresentState.isFrozen = action.isFrozen
        innerPresentState.isFullCover = action.isFullCover
        
        // 添加对应 新 store
        let presentedIndex = baseOnLevel + 1
        var arrStores: [Store<InnerPresentState>]
        if state.storage.innerPresentStores.count > presentedIndex {
            arrStores = state.storage.innerPresentStores[Int(presentedIndex)]
        } else {
            arrStores = []
        }
        arrStores.insert(.box(innerPresentState), at: 0)
        
        if state.storage.innerPresentStores.count > presentedIndex {
            state.storage.innerPresentStores[Int(presentedIndex)] = arrStores
        } else if state.storage.innerPresentStores.count == presentedIndex {
            state.storage.innerPresentStores.append(arrStores)
        } else {
            // 存储错误
            while state.storage.innerPresentStores.count < presentedIndex {
                state.storage.innerPresentStores.append([])
            }
            state.storage.innerPresentStores.append(arrStores)
        }
        
        // 根据情况标记展示
        state.topLevel = presentedIndex
        if baseOnLevel < state.turnAroundLevel {
            state.turnAroundLevel = baseOnLevel
        }
        
        checkSeekingOn(&state)
    }
    
    // MARK: - Dismiss
    
    static func reducerDismissAction(_ state: inout PresentState, _ action: PresentAction.InnerDismissAction) {
        var notFoundError: TargetRouteNotFound? = nil
        var targetLevel = getTargetLevel(on: state, action.targetLevel, &notFoundError)
        if let notFoundError = notFoundError {
            PresentMonitor.shared.record(event: .dismissFailed(notFoundError))
            return
        }
        if targetLevel >= action.dismissCount {
            targetLevel -= action.dismissCount
        } else {
            targetLevel = 0
        }
        state.topLevel = targetLevel
        if state.topLevel < state.turnAroundLevel {
            state.turnAroundLevel = state.topLevel
        }
        
        checkSeekingOn(&state)
    }
    
    // MARK: - Freeze
    
    static func reducerFreezeAction(_ state: inout PresentState, _ action: PresentAction.InnerFreezeAction) {
        var notFoundError: TargetRouteNotFound? = nil
        let targetLevel = getTargetLevel(on: state, action.targetLevel, &notFoundError)
        if let notFoundError = notFoundError {
            if action.isFrozen {
                PresentMonitor.shared.record(event: .freezeFailed(notFoundError))
            } else {
                PresentMonitor.shared.record(event: .unfreezeFailed(notFoundError))
            }
            return
        }
        if state.storage.innerPresentStores.count > targetLevel {
            state.storage.innerPresentStores[Int(targetLevel)].first?.apply(action: .freeze(action.isFrozen))
        } else {
            // fault
            PresentMonitor.shared.fatalError("The view you want to \(action.isFrozen ? "freeze" : "unfreeze") does not exist on level '\(targetLevel)'")
        }
    }
    
    // MARK: - Inner
    
    static func reducerInnerAction(_ state: inout PresentState, _ action: PresentAction.InnerAction) {
        switch action {
        case .didAppearOnLevel(let level):
            guard level == state.curLevel + 1 else {
                // fault
                PresentMonitor.shared.fatalError("The view did appear is not the top view. level=\(level), curLevel=\(state.curLevel)")
                return
            }
            if state.turnAroundLevel == state.curLevel {
                state.turnAroundLevel += 1
            }
            state.curLevel += 1
            checkSeekingOn(&state)
        case .didDisappearOnLevel(let level):
            guard level == state.curLevel else {
                // fault
                PresentMonitor.shared.fatalError("The view did disappear is not the top view. level=\(level), topLevel=\(state.curLevel)")
                return
            }
            // 移除对应 store
            if state.topLevel == state.curLevel && state.curLevel == state.turnAroundLevel {
                // 被动销毁最顶层
                while state.storage.innerPresentStores.count > state.curLevel  {
                    _ = state.storage.innerPresentStores.popLast()
                }
                state.curLevel -= 1
                state.topLevel = state.curLevel
                state.turnAroundLevel = state.curLevel
                return
            }
            // 存在转折，因为 turnAroundLevel <= 其他两个 level，三个 level 又不完全相等，必然 turnAroundLevel < Min(curLevel, topLevel)
            if state.topLevel >= state.curLevel {
                // 当前层需要保留最新 store
                let arrStores = state.storage.innerPresentStores[Int(state.curLevel)]
                state.storage.innerPresentStores[Int(state.curLevel)] = .init(arrStores.prefix(1))
            } else {
                // curLevel > topLevel, 完全是多出来的，可以直接移除
                while state.storage.innerPresentStores.count > state.curLevel  {
                    _ = state.storage.innerPresentStores.popLast()
                }
            }
            state.curLevel -= 1
            checkSeekingOn(&state, true)
        }
        
    }
    
    // MARK: - Get Level
    static func getTargetLevel(on presentState: PresentState, _ targetLevel: PresentLevelOf?, _ notFoundError: inout TargetRouteNotFound?) -> UInt {
        if let targetLevel = targetLevel {
            switch targetLevel {
            case .level(let theLevel):
                if theLevel > presentState.topLevel {
                    // 找不到对应 level，所有基于的都以 targetLevel 为主
                    notFoundError = .level(theLevel)
                }
                return theLevel
            case .route(let targetRoute):
                let foundStores = presentState.storage.innerPresentStores.prefix(Int(presentState.topLevel + 1)).last { arrStores in
                    arrStores.first?.route == targetRoute
                }
                if let foundLevel = foundStores?.first?.level {
                    return foundLevel
                }
                notFoundError = .route(targetRoute)
                return presentState.topLevel
            }
        }
        
        // 没有设置 target 相关内容，直接返回当前的
        return presentState.topLevel
    }
    
    // MARK: - Seeking
    
    /// 检查搜索回转状态，只有在 内部 disAppear 的时候 byForce = true，原因是这时候 isSeekingTurn = true
    static func checkSeekingOn(_ state: inout PresentState, _ byForce: Bool = false) {
        // turnAroundLevel 只可能 <= curLevel 并且 <= topLevel, 即 turnAroundLevel 必然是 三个中的最小值
        if state.curLevel == state.turnAroundLevel {
            // 直接转到 topLevel，因为 topLevel 不可能 < turnAroundLevel, 所以 topLevel >= curLevel
            if state.topLevel > state.curLevel {
                // 这里需要一层一层的 present
                let prevIsFullCover = state.storage.innerPresentStores[Int(state.curLevel + 1)].first?.isFullCover ?? false
                if let processStore = state.storage.innerPresentStores[Int(state.curLevel)].last {
                    if !processStore.isPresenting && !processStore.isFullCoverPresenting {
                        processStore.apply(action: .present(prevIsFullCover))
                    }
                } else {
                    // 这里存在问题 fault
                    if state.curLevel == 0 {
                        PresentMonitor.shared.fatalError("Inner present store not found on level '\(state.curLevel)', use 'PresentFlowView' to wrapper you view")
                    } else {
                        PresentMonitor.shared.fatalError("Inner present store not found on level '\(state.curLevel)'")
                    }
                }
            }
            state.isSeekingTurn = false
        } else {
            // turnAroundLevel < curLevel
            if state.isSeekingTurn && !byForce {
                // 正在往回搜寻那么可以退出了
                return
            }
            // 标记 isSeekingTurn，并 消失最顶部的 view
            if state.curLevel == 0 {
                // 这里不可能出现 为 0, fault
                PresentMonitor.shared.fatalError("Internal error. Root inner present state can not dismiss")
                return
            }
            state.isSeekingTurn = true
            guard let prevStore = state.storage.innerPresentStores[Int(state.curLevel - 1)].last else {
                // fault
                PresentMonitor.shared.fatalError("Internal error. Prev inner present store not exist")
                return
            }
            prevStore.apply(action: .dismiss)
        }
    }
}
