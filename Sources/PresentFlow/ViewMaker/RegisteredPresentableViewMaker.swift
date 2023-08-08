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

    let routeData: ViewRouteData
    
    func canMakeView(on sceneId: SceneId) -> Bool {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        // 先查找外部界面构造器
        if (presentCenter.externalManager ?? PresentCenter.shared.externalManager) != nil {
            return true
        }
        
        if (presentCenter.registerMap[routeData.route] ??
            PresentCenter.shared.registerMap[routeData.route]) != nil {
            return true
        }
        return false
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        // 先查找外部界面构造器
        if let externalManager = presentCenter.externalManager ??
            PresentCenter.shared.externalManager {
            return externalManager.viewMaker(routeData, sceneId)
        }

        if let wrapper = presentCenter.registerMap[routeData.route] ??
            PresentCenter.shared.registerMap[routeData.route]{
            return wrapper.makeView(routeData.initData)
        }
        
        // 这里需要记录异常
        PresentMonitor.shared.fatalError("No registered presentable view for route '\(routeData.route.description)'")
        return PresentNotFoundViewMaker(route: routeData.route).makeView(on: sceneId)
    }
    
    func modify(on sceneId: SceneId, _ view: AnyView) -> AnyView {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        // 先查找外部界面构造器
        if let externalManager = presentCenter.externalManager ?? PresentCenter.shared.externalManager {
            return externalManager.modifier(routeData.route, sceneId, view)
        }
        
        if let wrapper = presentCenter.registerMap[routeData.route] ??
            PresentCenter.shared.registerMap[routeData.route] {
            return wrapper.modifier(view)
        }
        
        return view
    }
}
