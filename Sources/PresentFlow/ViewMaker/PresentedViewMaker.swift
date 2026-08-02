//
//  PresentedViewMaker.swift
//  
//
//  Created by 黄磊 on 2022/9/4.
//

import SwiftUI
import ViewFlow

/// 展示界面的包装器，暂时内部使用
protocol PresentedViewMaker: Sendable {
    mutating func canMakeView(on sceneId: SceneId) -> Bool
    @MainActor
    func makeView(on sceneId: SceneId) -> AnyView
    @MainActor
    func modify(on sceneId: SceneId, _ view: AnyView) -> AnyView
    /// 取消路由（展示成功后界面被关闭时调用，对非结果路由为 no-op）
    func cancelRoute()
    /// 路由展示失败时调用（对非结果路由为 no-op）
    func failRoute(reason: String)
}

extension PresentedViewMaker {
    func modify(on sceneId: SceneId, _ view: AnyView) -> AnyView {
        return view
    }
    func cancelRoute() {}
    func failRoute(reason: String) {}
}

extension EmptyView: PresentedViewMaker {
    
    func canMakeView(on sceneId: SceneId) -> Bool {
        return false
    }
    
    func makeView(on sceneId: SceneId) -> AnyView {
        .init(self)
    }
}
