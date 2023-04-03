//
//  PresentState.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/8/3.
//

import DataFlow
import ViewFlow
import SwiftUI


public struct PresentState: FullSceneSharableState {
    public typealias UpState = SceneState
    
    public typealias BindAction = PresentAction
    
    let sceneId: SceneId
    
    /// 当前显示层级，curLevel=0 标识没有 present 任何 View
    public var curLevel: UInt = 0
    /// 目标显示层级，外部只能控制目标层级，因为 present 和 dismiss 只能一个接一个的进行
    var targetLevel: UInt = 0
    
    /// 回转层级，默认跟 curLevel 相等
    var turnAroundLevel: UInt = 0
    
    /// 是否正在搜寻 turn 节点
    var isSeekingTurn: Bool = false
        
    /// InnerPresentState 存储器
    final class PresentStorage {
        /// 内部展示状态对应 store， 之所以用两层数组，是为了支持同时任意的 present 和 dismiss
        var innerPresentStores: [[Store<InnerPresentState>]] = []
    }
    
    let storage: PresentStorage = .init()
    
    let presentCenter: PresentCenter = .init()
    
    public init() {
        self.init(on: .main)
    }
    
    public init(on sceneId: SceneId) {
        self.sceneId = sceneId
    }
    
    public static func loadReducers(on store: Store<PresentState>) {
        store.registerDefault { state, action in
            PresentReducer.reducer(&state, action)
        }
    }
}

/// store maker
extension PresentState {
    /// 获取 Inner Present Store
    func innerPresentStoreOnLevel(_ level: UInt, _ createIfNeed: Bool = false) -> Store<InnerPresentState> {
        if level < storage.innerPresentStores.count {
            if let lastStore = storage.innerPresentStores[Int(level)].last {
                return lastStore
            }
        }
        var newStore: Store<InnerPresentState>? = nil
        if createIfNeed {
            while level >= storage.innerPresentStores.count {
                if level == storage.innerPresentStores.count {
                    // 这里一般时第一层
                    let newState = InnerPresentState(level: level)
                    newStore = Store<InnerPresentState>.box(newState)
                    storage.innerPresentStores.append([newStore!])
                } else {
                    storage.innerPresentStores.append([])
                }
            }
        }
        
        if let newStore = newStore {
            return newStore
        }
        
        // 这里正常情况不会出现
        PresentMonitor.shared.fatalError("Get inner present store on level '\(level)' failed. Store not exist")
        let newState = InnerPresentState(level: level)
        return .box(newState)
    }
}
