//
//  PresentNotFoundViewMaker.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/9/22.
//

import SwiftUI
import DataFlow
import ViewFlow

public struct PresentNotFoundViewMaker : PresentedViewMaker {
    let route: AnyViewRoute
    
    public init(route: AnyViewRoute) {
        self.route = route
    }
    
    public func makeView(on sceneId: SceneId) -> AnyView {        
        let notFoundView = VStack {
            Text("Present view not found with route '\(route.description)'")
            Button("Dismiss") {
                Store<PresentState>.shared(on: sceneId).dismiss()
            }
        }
        return AnyView(notFoundView)
    }
}
