//
//  RegisteredPresentableViewMaker.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/9/22.
//

import SwiftUI

struct RegisteredPresentableViewMaker<InitData> : PresentedViewMaker {
    var route: PresentRoute<InitData>
    var data: InitData
    
    func makeView() -> AnyView {
        let presentCenter = PresentState.presentStore.presentCenter
        if let wrapper = presentCenter.registerMap[AnyHashable(route)] {
            return wrapper.makeView(data)
        }
        if let wrapper = PresentCenter.shared.registerMap[AnyHashable(route)] {
            return wrapper.makeView(data)
        }
        // 这里需要记录异常
        PresentMonitor.shared.fatalError("No registed presentable view for route '\(route)'")
        return NotFoundViewMaker(route: route.eraseToAnyRoute()).makeView()
    }
}
