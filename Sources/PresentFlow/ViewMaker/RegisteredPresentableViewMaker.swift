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
    
    // 正式环境不弹出界面
    func canMakeView(on sceneId: SceneId) -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
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
        PresentMonitor.shared.fatalError("No registed presentable view for route '\(routeData.route)'")
        return PresentNotFoundViewMaker(route: routeData.route).makeView(on: sceneId)
    }
}
