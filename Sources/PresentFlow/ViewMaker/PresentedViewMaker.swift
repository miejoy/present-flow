//
//  PresentedViewMaker.swift
//  
//
//  Created by 黄磊 on 2022/9/4.
//

import SwiftUI
import ViewFlow

/// 展示界面的包装器，暂时内部使用
protocol PresentedViewMaker {
    func canMakeView(on sceneId: SceneId) -> Bool
    func makeView(on sceneId: SceneId) -> AnyView
}

extension EmptyView: PresentedViewMaker {
    
    func canMakeView(on sceneId: SceneId) -> Bool {
        return false
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        .init(self)
    }
}
