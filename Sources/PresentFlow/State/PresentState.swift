//
//  PresentState.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/8/3.
//

import DataFlow
import ViewFlow
import SwiftUI

// 展示流相关状态
public struct PresentState: FullSceneWithIdSharableState {
    public typealias UpState = SceneState
    
    public typealias BindAction = PresentAction
    
    /// 当前场景ID
    public let sceneId: SceneId
    
    /// 当前显示层级，curLevel=0 标识没有 present 任何 View
    public var curLevel: UInt = 0
    /// 目标显示层级，外部只能控制目标层级，因为 present 和 dismiss 只能一个接一个的进行
    public var topLevel: UInt = 0
    
    /// 回转层级，默认跟 curLevel 相等
    var turnAroundLevel: UInt = 0
    
    /// 是否正在搜寻 turn 节点
    var isSeekingTurn: Bool = false
    
    public init(sceneId: SceneId) {
        self.sceneId = sceneId
    }
    
    public static func loadReducers(on store: Store<PresentState>) {
        store.registerDefault { [weak store] state, action in
            guard let store = store else { return }
            PresentReducer.reducer(store, &state, action)
        }
    }
}

// MARK: - PresentStorage

/// InnerPresentState 存储器
final class PresentStorage {
    /// 内部展示状态对应 store， 之所以用两层数组，是为了支持同时任意的 present 和 dismiss
    var innerPresentStores: [[Store<InnerPresentState>]] = []
}

extension StateOnStoreStorageKey where Value == PresentStorage, State == PresentState {
    static let storage: Self = .init("storage")
}

extension Store where State == PresentState {
    nonisolated var storage: PresentStorage {
        self[.storage, default: PresentStorage()]
    }
}

// MARK: - PresentCenter

extension StateOnStoreStorageKey where Value == PresentCenter, State == PresentState {
    static let presentCenter: Self = .init("presentCenter")
}

extension Store where State == PresentState {
    nonisolated var presentCenter: PresentCenter {
        self[.presentCenter, default: PresentCenter()]
    }
}

/// store maker
extension Store where State == PresentState {
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
