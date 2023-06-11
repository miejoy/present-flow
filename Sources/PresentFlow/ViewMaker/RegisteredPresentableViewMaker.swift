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
        if presentCenter.externalViewMaker != nil {
            return true
        }
        if PresentCenter.shared.externalViewMaker != nil {
            return true
        }
        if presentCenter.registerMap[routeData.route] != nil {
            return true
        }
        if PresentCenter.shared.registerMap[routeData.route] != nil {
            return true
        }
        return false
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        let presentCenter = Store<PresentState>.shared(on: sceneId).presentCenter
        // 先查找外部界面构造器
        if let viewMaker = presentCenter.externalViewMaker {
            return viewMaker(routeData, sceneId)
        }
        if let viewMaker = PresentCenter.shared.externalViewMaker {
            return viewMaker(routeData, sceneId)
        }
        if let wrapper = presentCenter.registerMap[routeData.route] {
            return wrapper.makeView(routeData.initData)
        }
        if let wrapper = PresentCenter.shared.registerMap[routeData.route] {
            return wrapper.makeView(routeData.initData)
        }
        // 这里需要记录异常
        PresentMonitor.shared.fatalError("No registered presentable view for route '\(routeData.route.description)'")
        return PresentNotFoundViewMaker(route: routeData.route).makeView(on: sceneId)
    }
}
