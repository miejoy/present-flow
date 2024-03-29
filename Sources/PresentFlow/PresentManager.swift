//
//  PresentManager.swift
//  
//
//  Created by 黄磊 on 2023/3/30.
//  PresentManager = Store<PresentState>

import Foundation
import DataFlow
import ViewFlow

extension Store where State == PresentState {
    // MARK: - Present
    
    // MARK: -Present With View
    /// 展示对应界面
    ///
    /// - Parameter view: 需要展示的界面
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func present<P: PresentableView>(_ view: P) {
        self.send(action: .present(view))
    }
    
    // MARK: -Present With View Type
    /// 展示对应界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func present<P: PresentableView>(_ viewType: P.Type, _ data: P.InitData) {
        self.send(action: .present(P.self, data))
    }
    
    /// 展示对应界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    @inlinable
    public func present<P: VoidPresentableView>(_ viewType: P.Type) {
        self.send(action: .present(P.self))
    }
    
    // MARK: -Present With Route
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func present<InitData>(_ route: ViewRoute<InitData>, _ data: InitData) {
        self.send(action: .present(route, data))
    }
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    @inlinable
    public func present(_ route: ViewRoute<Void>) {
        self.send(action: .present(route))
    }
    
    // MARK: -Present With RouteData
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter routeData: 需要展示界面的路由数据
    @inlinable
    public func present(_ routeData: ViewRouteData) {
        self.send(action: .present(routeData))
    }
    
    // MARK: -Present With AnyRoute
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    /// - Parameter data: 初始化展示界面需要的数据，如果数据类型错误或者不能被转化，则对应界面不会展示
    @inlinable
    public func present(_ route: AnyViewRoute, _ data: Any = Void()) {
        self.send(action: .present(route, data))
    }
    
    // MARK: - Dismiss
    
    /// 消失最顶层界面
    @inlinable
    public func dismissTopView() {
        self.send(action: .dismissTopView())
    }
    
    /// 消失最顶层界面
    @inlinable
    public func dismissViewOnLevel(_ level: UInt) {
        self.send(action: .dismissViewOnLevel(level))
    }
    
    /// 消失上层所以界面，直接到根界面
    @inlinable
    public func dismissToRootView() {
        self.send(action: .dismissToViewOnLevel(0))
    }
}

#if os(iOS) || os(tvOS) || os(watchOS)
// MARK: - Present Full Cover

extension Store where State == PresentState {
    /// 展示对应界面
    ///
    /// - Parameter view: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func presentFullCover<P: PresentableView>(_ view: P) {
        self.send(action: .present(view, isFullCover: true))
    }
    
    /// 展示对应界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func presentFullCover<P: PresentableView>(_ viewType: P.Type, _ data: P.InitData) {
        self.send(action: .present(P.self, data, isFullCover: true))
    }
    
    /// 展示对应界面
    ///
    /// - Parameter viewType: 需要展示的界面类型
    @inlinable
    public func presentFullCover<P: VoidPresentableView>(_ viewType: P.Type) {
        self.send(action: .present(P.self, isFullCover: true))
    }
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    /// - Parameter data: 初始化展示界面需要的数据
    @inlinable
    public func presentFullCover<InitData>(_ route: ViewRoute<InitData>, _ data: InitData) {
        self.send(action: .present(route, data, isFullCover: true))
    }
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    @inlinable
    public func presentFullCover(_ route: ViewRoute<Void>) {
        self.send(action: .present(route, isFullCover: true))
    }
    
    /// 展示对应路由的界面，使用路由操作前，必须确保对应路由已使用 PresentCenter 注册
    ///
    /// - Parameter route: 需要展示界面的路由
    @inlinable
    public func presentFullCover(_ routeData: ViewRouteData) {
        self.send(action: .present(routeData, isFullCover: true))
    }
    
}
#endif
