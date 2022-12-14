//
//  PresentCenter.swift
//  
//
//  Created by 黄磊 on 2022/9/11.
//

import Foundation
import SwiftUI

public final class PresentCenter {
    public static var shared: PresentCenter = .init()
    
    var registerMap: [AnyHashable: PresentableViewWrapper] = [:]
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registeDefaultPresentableView<V: PresentableView>(_ presentableViewType: V.Type) {
        let route = V.defaultRoute
        registePresentableView(V.self, for: route)
    }
    
    /// 使用默认路由注册对应展示界面
    @inlinable
    public func registeDefaultPresentableView<V: PresentableView>(_ presentableViewType: V.Type) where V.InitData == Void {
        let route = V.defaultRoute
        registePresentableView(V.self, for: route)
    }
    
    /// 注册对应展示界面
    public func registePresentableView<V: PresentableView>(_ presentableViewType: V.Type, for route: PresentRoute<V.InitData>) {
        let key = AnyHashable(route)
        if registerMap[key] != nil {
            PresentMonitor.shared.fatalError("Duplicate registration of PresentableView '\(key)'")
        }
        registerMap[key] = .init(V.self)
    }
    
    /// 注册对应展示界面
    public func registePresentableView<V: PresentableView>(_ presentableViewType: V.Type, for route: PresentRoute<V.InitData>) where V.InitData == Void {
        let key = AnyHashable(route)
        if registerMap[key] != nil {
            PresentMonitor.shared.fatalError("Duplicate registration of PresentableView '\(key)'")
        }
        registerMap[key] = .init(V.self)
    }
}

struct PresentableViewWrapper {
    
    let run: (Any) -> AnyView
    
    init<V: PresentableView>(_ presentableViewType: V.Type) {
        self.run = { data -> AnyView in
            if let data = data as? V.InitData {
                return AnyView(V(data))
            }
            // 这里需要记录异常
            PresentMonitor.shared.fatalError("Make presentable view '\(String(describing: V.self))' failed. Convert to initialization data of '\(String(describing: V.InitData.self))' failed")
            return AnyView(EmptyView())
        }
    }
    
    init<V: PresentableView>(_ presentableViewType: V.Type) where V.InitData == Void  {
        self.run = { data -> AnyView in
            return AnyView(V(Void()))
        }
    }
    
    func makeView(_ data: Any) -> AnyView {
        return run(data)
    }
}


