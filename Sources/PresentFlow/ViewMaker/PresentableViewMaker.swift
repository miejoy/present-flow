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
    let data: P.InitData
    
    func canMakeView(on sceneId: SceneId) -> Bool {
        return true
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        return AnyView(P(data))
    }
}
