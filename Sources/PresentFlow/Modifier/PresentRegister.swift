//
//  File.swift
//  
//
//  Created by 黄磊 on 2022/9/21.
//

import SwiftUI

extension View {
    /// 注册对应可展示界面
    public func registerPresentableView<V: PresentableView>(_ presentableViewType: V.Type, for route: PresentRoute<V.InitData>) -> some View {
        PresentState.presentStore.presentCenter.registePresentableView(presentableViewType, for: route)
        return self
    }
    
    /// 在回调内注册对应可展示界面
    public func registerPresentOn(_ callback: (_ presentCenter: PresentCenter) -> Void) -> some View {
        callback(PresentState.presentStore.presentCenter)
        return self
    }
}
