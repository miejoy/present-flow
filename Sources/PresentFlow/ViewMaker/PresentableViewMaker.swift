//
//  PresentableViewMaker.swift
//  
//
//  Created by 黄磊 on 2022/9/12.
//

import Foundation
import SwiftUI
import ViewFlow

struct PresentableViewMaker<P: PresentableView> : PresentedViewMaker {
    let makeView: @MainActor () -> P
    
    init(makeView: @MainActor @escaping () -> P) {
        self.makeView = makeView
    }
    
    init(data initData: P.InitData) {
        self.init {
            P(initData)
        }
    }
    
    func canMakeView(on sceneId: SceneId) -> Bool {
        return true
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        return AnyView(makeView())
    }
}
