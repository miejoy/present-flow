//
//  NotFoundViewMaker.swift
//  DemoApp
//
//  Created by 黄磊 on 2022/9/22.
//

import SwiftUI

struct NotFoundViewMaker : PresentedViewMaker {
    var route: AnyPresentRoute
    
    func makeView() -> AnyView {
        let notFoundView = VStack {
            Text("Present view not found with route '\(route.description)'")
            Button("Dismiss") {
                PresentState.presentStore.dismiss()
            }
        }
        return AnyView(notFoundView)
    }
}
