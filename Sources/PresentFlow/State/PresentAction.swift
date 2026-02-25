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
        
        var baseOnLevel: PresentLevelOf?
    }
    
    /// 消失相关事件
    struct InnerDismissAction {
        /// 依赖于 target 的销毁数，为 0  时即表示 target 变为最顶层
        let dismissCount: UInt
        
        /// 目标层，没有的话则是最上层
        var targetLevel: PresentLevelOf?
    }
    
    /// 冻结相关事件
    struct InnerFreezeAction {
        let isFrozen: Bool
        
        /// 目标层，没有的话则是最上层
        var targetLevel: PresentLevelOf?
    }
    
    /// 内部使用事件
    enum InnerAction {
        case didAppearOnLevel(UInt)
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

/// 定位展示的层级
enum PresentLevelOf {
    case level(UInt)
    case route(AnyViewRoute)
    
    static func route<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .route(route.eraseToAnyRoute())
    }
}


// MARK: - Present

extension PresentAction {
    // MARK: -Present With View
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter view: 需要展示的界面
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView & Sendable>(
        _ view: P,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            view,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter view: 需要展示的界面
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView & Sendable, BaseOnInitData>(
        _ view: P,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            view,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }
    
    /// 展示对应界面，内部使用
    static func present<P: PresentableView & Sendable>(
        _ view: P,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOn: PresentLevelOf?
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButton {
            navState = .init(navigationTitle: navTitle, needCloseButton: needCloseButton)
        }
        let viewMaker = PresentableViewMaker<P>.init {
            view
        }
        var presentAction = InnerPresentAction(route: P.defaultRoute.eraseToAnyRoute(), viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        presentAction.baseOnLevel = baseOn
        #if os(iOS) || os(tvOS) || os(watchOS)
        if isFullCover {
            presentAction.isFullCover = isFullCover
        }
        #endif
        return .init(action: .present(presentAction))
    }
    
    // MARK: -Present With View Type
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            P.self,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<P: PresentableView, BaseOnInitData>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            P.self,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }
    
    /// 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<P: VoidPresentableView>(
        _ viewType: P.Type,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            P.self,
            Void(),
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<P: VoidPresentableView, BaseOnInitData>(
        _ viewType: P.Type,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            P.self,
            Void(),
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }
    
    /// 展示对应界面，内部使用
    static func present<P: PresentableView>(
        _ viewType: P.Type,
        _ data: P.InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOn: PresentLevelOf?
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButton {
            navState = .init(navigationTitle: navTitle, needCloseButton: needCloseButton)
        }
        let viewMaker = PresentableViewMaker<P>(data: data)
        var presentAction = InnerPresentAction(route: P.defaultRoute.eraseToAnyRoute(), viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        presentAction.baseOnLevel = baseOn
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
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present<InitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<InitData, BaseOnInitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }
    
    /// 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present(
        _ route: ViewRoute<Void>,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            route,
            Void(),
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的无初始化参数界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<BaseOnInitData>(
        _ route: ViewRoute<Void>,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            route,
            Void(),
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }
    
    /// 展示对应路由的界面，内部使用
    static func present<InitData>(
        _ route: ViewRoute<InitData>,
        _ data: InitData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOn: PresentLevelOf?
    ) -> Self {
        return .present(route.wrapper(data), navTitle: navTitle, needCloseButton: needCloseButton, needFreeze: needFreeze, isFullCover: isFullCover, baseOn: baseOn)
    }
    
    // MARK: -Present With RouteData
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter routeData: 需要展示界面对应的路由数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present(
        _ routeData: ViewRouteData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            routeData,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn:  (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter routeData: 需要展示界面对应的路由数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<BaseOnInitData>(
        _ routeData: ViewRouteData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            routeData,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }

    
    /// 展示对应路由的界面，内部使用
    static func present(
        _ routeData: ViewRouteData,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOn: PresentLevelOf?
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButton {
            navState = .init(navigationTitle: navTitle, needCloseButton: needCloseButton)
        }
        let viewMaker = RegisteredPresentableViewMaker(routeData: routeData)
        var presentAction = InnerPresentAction(route: routeData.route, viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        presentAction.baseOnLevel = baseOn
        #if os(iOS) || os(tvOS) || os(watchOS)
        if isFullCover {
            presentAction.isFullCover = isFullCover
        }
        #endif
        return .init(action: .present(presentAction))
    }
    
    // MARK: -Present With AnyRoute
    
    /// 展示对应 route 的界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnLevel: 基于某一层展示界面，这个层级必须小于等于展示流的最顶层层级
    /// - Returns Self: 返回构造好的自己
    public static func present(
        _ route: AnyViewRoute,
        _ data: Any = Void(),
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnLevel: UInt? = nil
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn:  (baseOnLevel != nil) ? .level(baseOnLevel!) : nil
        )
    }
    
    /// 基于 baseOnRoute 展示对应 route 的界面
    ///
    /// - Parameter route: 需要展示界面对应的路由
    /// - Parameter data: 初始化展示界面需要的数据
    /// - Parameter navTitle: 导航栏标题，如果非空则添加导航栏。默认不设置
    /// - Parameter needCloseButton: 是否需要导航栏关闭按钮，只要 navTitle 有值时，该设置才会生效。默认不设置
    /// - Parameter needFreeze: 是否需要冻结展示界面。默认 false
    /// - Parameter isFullCover: 是否使用全屏展示，只在 iOS || tvOS || watchOS 平台可用。默认 false
    /// - Parameter baseOnRoute: 基于某一个路由展示界面，这个路由对应界面必须在展示流中存在
    /// - Returns Self: 返回构造好的自己
    public static func present<BaseOnInitData>(
        _ route: AnyViewRoute,
        _ data: Any = Void(),
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOnRoute: ViewRoute<BaseOnInitData>
    ) -> Self {
        present(
            route,
            data,
            navTitle: navTitle,
            needCloseButton: needCloseButton,
            needFreeze: needFreeze,
            isFullCover: isFullCover,
            baseOn: .route(baseOnRoute)
        )
    }

    
    /// 展示对应路由的界面，内部使用
    static func present(
        _ route: AnyViewRoute,
        _ data: Any,
        navTitle: String? = nil,
        needCloseButton: Bool = false,
        needFreeze: Bool = false,
        isFullCover: Bool = false,
        baseOn: PresentLevelOf?
    ) -> Self {
        var navState: NavigationState? = nil
        if navTitle != nil || needCloseButton {
            navState = .init(navigationTitle: navTitle, needCloseButton: needCloseButton)
        }
        let viewMaker = RegisteredPresentableViewMaker(route: route, initData: data)
        var presentAction = InnerPresentAction(route: route, viewMaker: viewMaker, navigationState: navState, isFrozen: needFreeze)
        presentAction.baseOnLevel = baseOn
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
        .init(action: .dismiss(.init(dismissCount: 1, targetLevel:.route(route.eraseToAnyRoute()))))
    }
    
    /// 消失指定层的界面，对应界面上层界面也会同时消失
    ///
    /// - Parameter level: 需要消失界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func dismissViewOnLevel(_ level: UInt) -> Self {
        .init(action: .dismiss(.init(dismissCount: 1, targetLevel: .level(level))))
    }
    
    /// 消失指定路由的界面以上的界面
    ///
    /// - Parameter route: 需要消失以上界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func dismissToViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .dismiss(.init(dismissCount: 0, targetLevel: .route(route.eraseToAnyRoute()))))
    }
    
    /// 消失指定层以上的界面
    ///
    /// - Parameter level: 需要消失以上界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func dismissToViewOnLevel(_ level: UInt) -> Self {
        .init(action: .dismiss(.init(dismissCount: 0, targetLevel: .level(level))))
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
        .init(action: .freeze(.init(isFrozen: true, targetLevel: .route(route.eraseToAnyRoute()))))
    }
    
    /// 冻结指定层的界面
    ///
    /// - Parameter level: 需要冻结界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func freezeViewOnLevel(_ level: UInt) -> Self {
        .init(action: .freeze(.init(isFrozen: true, targetLevel: .level(level))))
    }
    
    /// 解冻指定路由的界面
    ///
    /// - Parameter route: 需要解冻界面对应的路由
    /// - Returns Self: 返回构造好的自己
    public static func unfreezeViewOnRoute<InitData>(_ route: ViewRoute<InitData>) -> Self {
        .init(action: .freeze(.init(isFrozen: false, targetLevel: .route(route.eraseToAnyRoute()))))
    }
    
    /// 解冻指定层的界面
    ///
    /// - Parameter level: 需要解冻界面对应的层级
    /// - Returns Self: 返回构造好的自己
    public static func unfreezeViewOnLevel(_ level: UInt) -> Self {
        .init(action: .freeze(.init(isFrozen: false, targetLevel: .level(level))))
    }
}


// MARK: - Inner
extension PresentAction {
    /// 通知当前层级界面已经显示完成，如果下一层还需要展示，就继续处理
    ///
    /// - Parameter level: 已经显示完成界面对应的层级
    /// - Returns Self: 返回构造好的自己
    static func didAppearOnLevel(_ level: UInt) -> Self {
        .init(action: .inner(.didAppearOnLevel(level)))
    }
    
    /// 通知当前层级界面已经消失，内部使用
    ///
    /// - Parameter level: 已经消失界面对应的层级
    /// - Returns Self: 返回构造好的自己
    static func didDisappearOnLevel(_ level: UInt) -> Self {
        .init(action: .inner(.didDisappearOnLevel(level)))
    }
}
