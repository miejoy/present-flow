//
//  PresentRegister.swift
//  
//
//  Created by 黄磊 on 2022/9/21.
//

import SwiftUI
import DataFlow
import ViewFlow

extension View {
    /// 注册对应可展示界面
    public func registerPresentableView<V: PresentableView>(_ presentableViewType: V.Type, for route: ViewRoute<V.InitData>, function: String = #function, line: Int = #line) -> some View {
        return self.modifier(PresentRegisterModifier(callback: { sceneId in
            let presentStore = Store<PresentState>.shared(on: sceneId)
            let callId = PresentCenter.CallId(function: function, line: line)
            if !presentStore.presentCenter.registerCallSet.contains(callId) {
                presentStore.presentCenter.registePresentableView(presentableViewType, for: route)
                presentStore.presentCenter.registerCallSet.insert(callId)
            }
        }))
        
    }
    
    /// 在回调内注册对应可展示界面
    public func registerPresentOn(_ callback: @escaping (_ presentCenter: PresentCenter) -> Void, function: String = #function, line: Int = #line) -> some View {
        return self.modifier(PresentRegisterModifier(callback: { sceneId in
            let presentStore = Store<PresentState>.shared(on: sceneId)
            let callId = PresentCenter.CallId(function: function, line: line)
            if !presentStore.presentCenter.registerCallSet.contains(callId) {
                callback(presentStore.presentCenter)
                presentStore.presentCenter.registerCallSet.insert(callId)
            }
        }))
    }
}

/// 展示修改器
public struct PresentRegisterModifier: ViewModifier {
    
    var callback: (SceneId) -> Void
    @Environment(\.sceneId) var sceneId
    
    public func body(content: Content) -> some View {
        return content.onAppear {
            callback(sceneId)
        }
    }
}

