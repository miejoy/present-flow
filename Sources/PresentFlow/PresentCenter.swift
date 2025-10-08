//
//  PresentCenter.swift
//  
//
//  Created by 黄磊 on 2022/9/11.
//

import Foundation
import SwiftUI
import ViewFlow

/// 展示注册中心，
/// 这里通过 shared 获取的注册中心，是注册整个App用到的展示界面
/// 如果通过 PresentState 获取的注册中心，是针对当前 scene 注册展示界面，会有些从这里查找注册的界面，查找不到会从 App 的注册中心查找
public final class PresentCenter {
    // 调用 ID，为了解决 SwifUI 中刷新界面时重复调用问题
    struct CallId: Hashable {
        let function: String
        let line: Int
    }
    
    public static let shared: PresentCenter = .init()
    
    var registerMap: [AnyViewRoute: PresentableViewWrapper] = [:]
    var registerCallSet: Set<CallId> = []
    var presentedModifier: ((_ content: PresentedModifier.Content, _ sceneId: SceneId, _ level: UInt) -> AnyView)? = nil
    
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
}

struct PresentableViewWrapper {
    
    let check: (Any) -> Any?
    let run: (Any) -> AnyView
    let modifier: (AnyView) -> AnyView
    
    init<V: PresentableView>(_ presentableViewType: V.Type) {
        self.init(presentableViewType, { $0 })
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type) where V.InitData == Void {
        self.init(presentableViewType, { $0 })
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type, _ modifier: @escaping (AnyView) -> some View = { $0 }) {
        self.check = { data in
            if data is V.InitData {
                return data
            } else if let data = V.makeInitializeData(from: data) {
                return data
            }
            return nil
        }
        self.run = { data -> AnyView in
            if let data = data as? V.InitData {
                return AnyView(V(data))
            } else if let data = V.makeInitializeData(from: data) {
                return AnyView(V(data))
            }
            // 这里需要记录异常
            PresentMonitor.shared.fatalError("Make presentable view '\(String(describing: V.self))' failed. Convert to initialization data of '\(String(describing: V.InitData.self))' failed")
            return AnyView(EmptyView())
        }
        self.modifier = { view in
            let newView = modifier(view)
            if let newView = newView as? AnyView {
                return newView
            }
            return AnyView(newView)
        }
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type, _ modifier: @escaping (AnyView) -> some View) where V.InitData == Void {
        self.check = { _ in () }
        self.run = { _ in
            return AnyView(V(Void()))
        }
        self.modifier = { view in
            let newView = modifier(view)
            if let newView = newView as? AnyView {
                return newView
            }
            return AnyView(newView)
        }
    }
    
    func makeView(_ data: Any) -> AnyView {
        return run(data)
    }
}


