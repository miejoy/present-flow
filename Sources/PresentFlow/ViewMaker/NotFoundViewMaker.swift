//
//  NotFoundViewMaker.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/9/22.
//

import SwiftUI
import DataFlow
import ViewFlow

struct NotFoundViewMaker : PresentedViewMaker {
    var route: AnyViewRoute
    
    func makeView(on sceneId: SceneId) -> AnyView {        
        let notFoundView = VStack {
            Text("Present view not found with route '\(route.description)'")
            Button("Dismiss") {
                Store<PresentState>.shared(on: sceneId).dismiss()
            }
        }
        return AnyView(notFoundView)
    }
}
