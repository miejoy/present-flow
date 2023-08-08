//
//  PresentCenter.swift
//  
//
//  Created by 黄磊 on 2022/9/11.
//

import Foundation
import SwiftUI
import ViewFlow

public final class PresentCenter {
    // 调用 ID，为了解决 SwifUI 中刷新界面时重复调用问题
    struct CallId: Hashable {
        let function: String
        let line: Int
    }
    
    struct ExternalManager {
        let viewMaker: (_ routeData: ViewRouteData, _ sceneId: SceneId) -> AnyView
        let modifier: (_ route: AnyViewRoute, _ sceneId: SceneId, _ view: AnyView) -> AnyView
    }
    
    public static let shared: PresentCenter = .init()
    
    var registerMap: [AnyViewRoute: PresentableViewWrapper] = [:]
    var registerCallSet: Set<CallId> = []
    var presentedModifier: ((_ content: PresentedModifier.Content, _ sceneId: SceneId, _ level: UInt) -> AnyView)? = nil
    var externalManager: ExternalManager? = nil
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registerDefaultPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type
    ) {
        let route = V.defaultRoute
        registerPresentableView(V.self, for: route)
    }
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registerDefaultPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type
    ) where V.InitData == Void {
        let route = V.defaultRoute
        registerPresentableView(V.self, for: route)
    }
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registerDefaultPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        _ modifier: @escaping (AnyView) -> some View
    ) {
        let route = V.defaultRoute
        registerPresentableView(V.self, for: route, modifier)
    }
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registerDefaultPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        _ modifier: @escaping (AnyView) -> some View
    ) where V.InitData == Void {
        let route = V.defaultRoute
        registerPresentableView(V.self, for: route, modifier)
    }
    
    /// 注册对应展示界面
    @inlinable
    public func registerPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        for route: ViewRoute<V.InitData>
    ) {
        registerPresentableView(presentableViewType, for: route, { $0 })
    }
    
    /// 注册对应展示界面
    @inlinable
    public func registerPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        for route: ViewRoute<V.InitData>
    ) where V.InitData == Void {
        registerPresentableView(presentableViewType, for: route, { $0 })
    }
    
    /// 注册对应展示界面
    public func registerPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        for route: ViewRoute<V.InitData>,
        _ modifier: @escaping (AnyView) -> some View
    ) {
        let key = route.eraseToAnyRoute()
        if registerMap[key] != nil {
            PresentMonitor.shared.fatalError("Duplicate registration of PresentableView '\(key)'")
        }
        registerMap[key] = .init(V.self, modifier)
    }
    
    /// 注册对应展示界面
    public func registerPresentableView<V: PresentableView>(
        _ presentableViewType: V.Type,
        for route: ViewRoute<V.InitData>,
        _ modifier: @escaping (AnyView) -> some View
    ) where V.InitData == Void {
        let key = route.eraseToAnyRoute()
        if registerMap[key] != nil {
            PresentMonitor.shared.fatalError("Duplicate registration of PresentableView '\(key)'")
        }
        registerMap[key] = .init(V.self, modifier)
    }
    
    public func registerExternalViewMaker(_ viewMaker: @escaping (_ routeData: ViewRouteData, _ sceneId: SceneId) -> AnyView, modifier: @escaping(_ route: AnyViewRoute, _ sceneId: SceneId, _ view: AnyView) -> AnyView = { $2 }) {
        if externalManager != nil {
            PresentMonitor.shared.fatalError("Duplicate registration of External View Maker")
        }
        externalManager = .init(viewMaker: viewMaker, modifier: modifier)
    }
}

struct PresentableViewWrapper {
    
    let run: (Any) -> AnyView
    let modifier: (AnyView) -> AnyView
    
    init<V: PresentableView>(_ presentableViewType: V.Type) {
        self.init(presentableViewType, { $0 })
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type) where V.InitData == Void {
        self.init(presentableViewType, { $0 })
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type, _ modifier: @escaping (AnyView) -> some View = { $0 }) {
        self.modifier = { view in
            let newView = modifier(view)
            if let newView = newView as? AnyView {
                return newView
            }
            return AnyView(newView)
        }
        self.run = { data -> AnyView in
            if let data = data as? V.InitData {
                return AnyView(V(data))
            }
            // 这里需要记录异常
            PresentMonitor.shared.fatalError("Make presentable view '\(String(describing: V.self))' failed. Convert to initialization data of '\(String(describing: V.InitData.self))' failed")
            return AnyView(EmptyView())
        }
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type, _ modifier: @escaping (AnyView) -> some View) where V.InitData == Void {
        self.modifier = { view in
            let newView = modifier(view)
            if let newView = newView as? AnyView {
                return newView
            }
            return AnyView(newView)
        }
        self.run = { _ in
            return AnyView(V(Void()))
        }
    }
    
    func makeView(_ data: Any) -> AnyView {
        return run(data)
    }
}


