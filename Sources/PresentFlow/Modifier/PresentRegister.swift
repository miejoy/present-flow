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
    public func registerPresentableView<V: PresentableView>(_ presentableViewType: V.Type, function: String = #function, line: Int = #line) -> some View {
        return registerPresentableView(presentableViewType, for: V.defaultRoute, function: function, line: line)
    }
    
    /// 注册对应可展示界面
    public func registerPresentableView<V: PresentableView>(_ presentableViewType: V.Type, for route: ViewRoute<V.InitData>, function: String = #function, line: Int = #line) -> some View {
        return self.modifier(PresentRegisterModifier(callback: { sceneId in
            let presentStore = Store<PresentState>.shared(on: sceneId)
            let callId = PresentCenter.CallId(function: function, line: line)
            if !presentStore.presentCenter.registerCallSet.contains(callId) {
                presentStore.presentCenter.registerPresentableView(presentableViewType, for: route)
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
    
    /// 注册展示后界面对应修饰回调（主要解决部分修饰无法应用到被展示界面的问题）
    public func registerPresentedModifier<V: View>(
        _ callback: @escaping (_ content: AnyView, _ sceneId: SceneId, _ level: UInt) -> V,
        function: String = #function,
        line: Int = #line
    ) -> some View {
        return self.modifier(PresentRegisterModifier(callback: { sceneId in
            let presentStore = Store<PresentState>.shared(on: sceneId)
            let callId = PresentCenter.CallId(function: function, line: line)
            if !presentStore.presentCenter.registerCallSet.contains(callId) {
                presentStore.presentCenter.presentedModifier = { AnyView(callback(AnyView($0), $1, $2)) }
                presentStore.presentCenter.registerCallSet.insert(callId)
            }
        }))
    }
}

/// 展示修改器
struct PresentRegisterModifier: ViewModifier {
    
    var callback: (SceneId) -> Void
    @Environment(\.sceneId) var sceneId
    
    func body(content: Content) -> some View {
        return content.onAppear {
            callback(sceneId)
        }
    }
}

struct PresentedModifier: ViewModifier {
    
    @Environment(\.sceneId) var sceneId
    @Environment(\.presentLevel) var level
    let callback: ((_ content: Content, _ sceneId: SceneId, _ level: UInt) -> AnyView)?
    
    func body(content: Content) -> AnyView {
        return callback?(content, sceneId, level) ?? AnyView(content)
    }
}
