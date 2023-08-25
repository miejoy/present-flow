//
//  RegisteredPresentableViewMaker.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/9/22.
//

import SwiftUI
import DataFlow
import ViewFlow

struct RegisteredPresentableViewMaker: PresentedViewMaker {

    let route: AnyViewRoute
    var initData: Any
    
    init(routeData: ViewRouteData) {
        self.init(route: routeData.route, initData: routeData.initData)
    }
    
    init(route: AnyViewRoute, initData: Any) {
        self.route = route
        self.initData = initData
    }
    
    mutating func canMakeView(on sceneId: SceneId) -> Bool {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        if let wrapper = presentCenter.registerMap[route] ?? PresentCenter.shared.registerMap[route] {
            if let data = wrapper.check(initData) {
                initData = data
                return true
            } else {
                PresentMonitor.shared.record(event: .presentFailedCannotMakeInitData(route))
            }
        } else {
            PresentMonitor.shared.record(event: .presentFailedNotRegister(route))
        }
        return false
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        if let wrapper = presentCenter.registerMap[route] ??
            PresentCenter.shared.registerMap[route]{
            return wrapper.makeView(initData)
        }
        
        // 这里需要记录异常
        PresentMonitor.shared.fatalError("No registered presentable view for route '\(route.description)'")
        return PresentNotFoundViewMaker(route: route).makeView(on: sceneId)
    }
    
    func modify(on sceneId: SceneId, _ view: AnyView) -> AnyView {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        
        if let wrapper = presentCenter.registerMap[route] ??
            PresentCenter.shared.registerMap[route] {
            return wrapper.modifier(view)
        }
        
        return view
    }
}
