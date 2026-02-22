//
//  InnerPresentState.swift
//  
//
//  Created by 黄磊 on 2022/9/18.
//

import DataFlow
import ViewFlow
import SwiftUI
import Combine

enum InnerPresentAction: Action {
    case present(Bool)
    case dismiss
    case freeze(Bool)
}

/// 内部使用展示状态
struct InnerPresentState: StorableState, ActionBindable, ReducerLoadableState {
    typealias BindAction = InnerPresentAction
    
    let level: UInt
    
    // MARK: - For Presented
    let route: AnyViewRoute
    let navigationState: NavigationState?
    let viewMaker: PresentedViewMaker
    
    /// 是否冻住当前 view，针对用户操作的
    var isFrozen = false
    
    /// 标记当前 view 是不是全屏幕，给上级 state 使用
    var isFullCover = false
        
    // MARK: - For Presenting
    /// 是否正在展示其他界面
    var isPresenting: Bool = false
    var isFullCoverPresenting: Bool = false
    
    init(
        level: UInt,
        route: AnyViewRoute = ViewRoute<Void>("").eraseToAnyRoute(),
        navigationState: NavigationState? = nil,
        viewMaker: PresentedViewMaker = EmptyView()
    ) {
        self.level = level
        self.route = route
        self.navigationState = navigationState
        self.viewMaker = viewMaker
    }
    
    @MainActor
    func makeView(_ sceneId: SceneId, _ closeView: AnyView) -> AnyView {
        let presentStore = Store<PresentState>.shared(on: sceneId)
        var view = viewMaker.makeView(on: sceneId)
        view = AnyView(view.environment(\.suggestNavTitle, navigationState?.navigationTitle))
        if let navigationState = navigationState {
            #if os(iOS) || os(tvOS)
            if navigationState.needCloseButton {
                let toolbarView = view.toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            presentStore.dismissViewOnLevel(level)
                        } label: {
                            closeView
                        }
                    }
                }
                view = AnyView(toolbarView)
            }
            #endif
        }
        return viewMaker.modify(on: sceneId, view)
    }
    
    static func loadReducers(on store: Store<InnerPresentState>) {
        store.registerDefault { state, action in
            switch action {
            case .present(let isFullCover):
                if isFullCover {
                    state.isFullCoverPresenting = true
                } else {
                    state.isPresenting = true
                }
            case .dismiss:
                state.isPresenting = false
                state.isFullCoverPresenting = false
            case .freeze(let isFrozen):
                state.isFrozen = isFrozen
            }
        }
    }
}

@MainActor
@propertyWrapper
struct InnerPresentWrapper : @preconcurrency DynamicProperty {
    
    @ObservedObject
    var storage: InnerPresentWrapperStorage
    @Environment(\.sceneId)
    var sceneId
    
    init(_ level: UInt) {
        self._storage = .init(wrappedValue: .init(level: level))
    }
    
    var wrappedValue: InnerPresentState {
        get {
            storage.store!.state
        }
        
        nonmutating set {
            storage.store!.state = newValue
        }
    }
    
    var projectedValue: Store<InnerPresentState> {
        storage.store!
    }
    
    func update() {
        if storage.store == nil {
            storage.configIfNeed(sceneId)
        }
    }
}

@MainActor
final class InnerPresentWrapperStorage: ObservableObject {
    let level: UInt
    @Published
    var refreshTrigger: Bool = false
    var store: Store<InnerPresentState>? = nil
    var cancellable: AnyCancellable? = nil
    
    init(level: UInt) {
        self.level = level
    }
    
    func configIfNeed(_ sceneId: SceneId) {
        if store == nil {
            let newStore = Store<PresentState>.shared(on: sceneId).innerPresentStoreOnLevel(level, level == 0)
            self.cancellable = newStore.addObserver { [weak self] new, old in
                self?.refreshTrigger.toggle()
            }
            self.store = newStore
        }
    }
}

struct NavigationState {
    var navigationTitle: String? = nil
    var needCloseButton: Bool = false
}
