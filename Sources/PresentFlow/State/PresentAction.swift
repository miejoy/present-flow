//
//  PresentAction.swift
//  
//
//  Created by 黄磊 on 2022/9/5.
//

import DataFlow
import ViewFlow

/// 展示相关事件
public struct PresentAction: Action {
    /// 展示相关事件
    struct InnerPresentAction {
        let route: AnyViewRoute
        let viewMaker: PresentedViewMaker
        let navigationState: NavigationState?
        var isFrozen = false
        var isFullCover = false
        
        var baseOnRoute: AnyViewRoute? = nil
        var baseOnLevel: UInt? = nil
    }
    
    /// 消失相关事件
    struct InnerDismissAction {
        /// 依赖于 target 的销毁数，为 0  时即表示 target 变为最顶层
        let dismissCount: UInt
        
        /// 目标层，没有的话则是最上层
        var targetRoute: AnyViewRoute? = nil
        var targetLevel: UInt? = nil
    }
    
    /// 冻结相关事件
    struct InnerFreezeAction {
        let isFrozen: Bool
        
        /// 目标层，没有的话则是最上层
        var targetRoute: AnyViewRoute? = nil
        var targetLevel: UInt? = nil
    }
    
    /// 内部使用事件
    enum InnerAction {
        case didDisappearOnLevel(UInt)
    }
    
    /// 内部事件
    enum ContentAction {
        case present(InnerPresentAction)
        
        case dismiss(InnerDismissAction)

        case freeze(InnerFreezeAction)
        
        case inner(InnerAction)
    }
    
    var action: ContentAction
}


// MARK: - Present

extension PresentAction {
    // MARK: -Present With View
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnLevel: 基于那一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            P.self,
            data,
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: ViewRoute<Void>?.none,
            baseOnLevel: baseOnLevel
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnRoute: 基于那一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView, BaseOnInitData>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            P.self,
            data,
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: baseOnRoute,
            baseOnLevel: nil
        )
    }
    
    /// 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnLevel: 基于那一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<P: VoidPresentableView>(
        _ route: P.Type,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            P.self,
            Void(),
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: ViewRoute<Void>?.none,
            baseOnLevel: baseOnLevel
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnRoute: 基于那一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<P: VoidPresentableView, BaseOnInitData>(
        _ route: P.Type,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            P.self,
            Void(),
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: baseOnRoute
        )
    }
    
    /// 展示对应界面，内部使用
    static func present<P: PresentableView, BaseOnInitData>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>? = nil,
        baseOnLevel: UInt? = nil
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButtom {
            navState = .init(navigationTitle: navTitle, needCloseButtom: needCloseButtom)
        }
        let viewMaker = PresentableViewMaker<P>(data: data)
        var presentAction = InnerPresentAction(route: P.defaultRoute.eraseToAnyRoute(), viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        if let baseOnRoute = baseOnRoute {
            presentAction.baseOnRoute = baseOnRoute.eraseToAnyRoute()
        } else if let baseOnLevel = baseOnLevel {
            presentAction.baseOnLevel = baseOnLevel
        }
        #if os(iOS) || os(tvOS) || os(watchOS)
        if isFullCover {
            presentAction.isFullCover = isFullCover
        }
        #endif
        return .init(action: .present(presentAction))
    }
    
    // MARK: -Present With Route
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnLevel: 基于那一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<InitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: ViewRoute<Void>?.none,
            baseOnLevel: baseOnLevel
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnRoute: 基于那一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<InitData, BaseOnInitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: baseOnRoute,
            baseOnLevel: nil
        )
    }
    
    /// 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnLevel: 基于那一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present(
        _ route: ViewRoute<Void>,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            route,
            Void(),
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: ViewRoute<Void>?.none,
            baseOnLevel: baseOnLevel
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButtom: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台剩下。默认 false
    /// - Parameter baseOnRoute: 基于那一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<BaseOnInitData>(
        _ route: ViewRoute<Void>,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            route,
            Void(),
            navTitle: navTitle,
            needCloseButtom: needCloseButtom,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOnRoute: baseOnRoute
        )
    }
    
    /// 展示对应路由的界面，内部使用
    static func present<InitData, BaseOnInitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButtom: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>? = nil,
        baseOnLevel: UInt? = nil
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButtom {
            navState = .init(navigationTitle: navTitle, needCloseButtom: needCloseButtom)
        }
        let viewMaker = RegisteredPresentableViewMaker(route: route, data: data)
        var presentAction = InnerPresentAction(route: route.eraseToAnyRoute(), viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        if let baseOnRoute = baseOnRoute {
            presentAction.baseOnRoute = baseOnRoute.eraseToAnyRoute()
        } else if let baseOnLevel = baseOnLevel {
            presentAction.baseOnLevel = baseOnLevel
        }
        #if os(iOS) || os(tvOS) || os(watchOS)
        if isFullCover {
            presentAction.isFullCover = isFullCover
        }
        #endif
        return .init(action: .present(presentAction))
    }
}


// MARK: - Dismiss

extension PresentAction {
    
    /// 消失最上层展示界面
    ///
    /// - Returns Self: 返回构造好的自己
    public static func dismissTopView() -> Self {
        .init(action: .dismiss(.init(dismissCount: 1)))
    }
    
    /// 消失指定路由的界面，对应界面上层界面也会同时消失
    ///
    /// - Parameter route: 需要消失界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func dismissViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .dismiss(.init(dismissCount: 1, targetRoute: route.eraseToAnyRoute())))
    }
    
    /// 消失指定层的界面，对应界面上层界面也会同时消失
    ///
    /// - Parameter level: 需要消失界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func dismissViewOnLevel(_ level: UInt) -> Self {
        .init(action: .dismiss(.init(dismissCount: 1, targetLevel: level)))
    }
    
    /// 消失指定路由的界面以上的界面
    ///
    /// - Parameter route: 需要消失以上界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func dismissToViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .dismiss(.init(dismissCount: 0, targetRoute: route.eraseToAnyRoute())))
    }
    
    /// 消失指定层以上的界面
    ///
    /// - Parameter level: 需要消失以上界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func dismissToViewOnLevel(_ level: UInt) -> Self {
        .init(action: .dismiss(.init(dismissCount: 0, targetLevel: level)))
    }
}

// MARK: - Freeze

extension PresentAction {
    /// 冻结最上层展示界面
    ///
    /// - Returns Self: 返回构造好的自己
    public static func freezeTopView() -> Self {
        .init(action: .freeze(.init(isFrozen: true)))
    }
    
    /// 解冻最上层展示界面
    ///
    /// - Returns Self: 返回构造好的自己
    public static func unfreezeTopView() -> Self {
        .init(action: .freeze(.init(isFrozen: false)))
    }
    
    /// 冻结指定路由的界面
    ///
    /// - Parameter route: 需要冻结界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func freezeViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .freeze(.init(isFrozen: true, targetRoute: route.eraseToAnyRoute())))
    }
    
    /// 冻结指定层的界面
    ///
    /// - Parameter level: 需要冻结界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func freezeViewOnLevel(_ level: UInt) -> Self {
        .init(action: .freeze(.init(isFrozen: true, targetLevel: level)))
    }
    
    /// 解冻指定路由的界面
    ///
    /// - Parameter route: 需要解冻界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func unfreezeViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .freeze(.init(isFrozen: false, targetRoute: route.eraseToAnyRoute())))
    }
    
    /// 解冻指定层的界面
    ///
    /// - Parameter level: 需要解冻界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func unfreezeViewOnLevel(_ level: UInt) -> Self {
        .init(action: .freeze(.init(isFrozen: false, targetLevel: level)))
    }
}


// MARK: - Inner
extension PresentAction {
    /// 通知当前层级界面已经消失，内部使用
    ///
    /// - Parameter level: 已经消失界面对应的层级
    /// - Returns Self: 返回构造好的自己
    static func didDisappearOnLevel(_ level: UInt) -> Self {
        .init(action: .inner(.didDisappearOnLevel(level)))
    }
}
