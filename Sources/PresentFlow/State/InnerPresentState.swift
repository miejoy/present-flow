//
//  InnerPresentState.swift
//  
//
//  Created by 黄磊 on 2022/9/18.
//

import DataFlow
import SwiftUI

enum InnerPresentAction: Action {
    case present(Bool)
    case dismiss
    case freeze(Bool)
}

/// 内部使用展示状态
struct InnerPresentState: StorableState, ActionBindable, ReducerLoadableState {
    typealias BindAction = InnerPresentAction
    
    let level: UInt
    
    @Environment(\.presentManager) var presentManager
    
    // MARK: - For Presented
    let route: AnyPresentRoute
    let navigationState: NavigationState?
    let viewMaker: PresentedViewMaker
    
    /// 是否冻住当前 view
    var isFrozen = false
    
    /// 标记当前 view 是不是全屏幕，给上级 state 使用
    var isFullCover = false
    
    /// 关闭按钮
    @Environment(\.presentedCloseView) var closeView
    
    // MARK: - For Presenting
    /// 是否正在展示其他界面
    var isPresenting: Bool = false
    var isFullCoverPresenting: Bool = false
    
    init(
        level: UInt,
        route: AnyPresentRoute = PresentRoute<Void>().eraseToAnyRoute(),
        navigationState: NavigationState? = nil,
        viewMaker: PresentedViewMaker = EmptyView()
    ) {
        self.level = level
        self.route = route
        self.navigationState = navigationState
        self.viewMaker = viewMaker
    }
    
    func makeView() -> AnyView {
        var view = viewMaker.makeView()
        if let navigationState = navigationState {
            if let navigationTitle = navigationState.navigationTitle {
                let viewWithTitle = view.navigationTitle(navigationTitle)
                #if os(iOS) || os(watchOS)
                if #available(iOS 14.0, watchOS 8.0, *) {
                    view = AnyView(viewWithTitle.navigationBarTitleDisplayMode(.inline))
                } else {
                    view = AnyView(viewWithTitle)
                }
                #else
                view = AnyView(viewWithTitle)
                #endif
            }
            
            #if os(iOS) || os(tvOS)
            if navigationState.needCloseButtom {
                view = AnyView(view.navigationBarItems(leading: Button(action: {
                    presentManager.dismiss()
                }, label: {
                    closeView
                })))
            }
            #endif
        }
        return view
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


struct NavigationState {
    var navigationTitle: String? = nil
    var needCloseButtom: Bool = false
}
