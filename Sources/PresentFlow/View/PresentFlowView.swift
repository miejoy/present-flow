//
//  PresentFlowView.swift
//  
//
//  Created by 黄磊 on 2022/8/7.
//

import SwiftUI
import DataFlow
import ViewFlow

// 包装展示流的界面，可以用这个来包装对于 界面 实现内部 界面 可展示其他界面
public struct PresentFlowView<Content: View>: View {
    
    var level: UInt
    
    @ViewBuilder var content: Content
    @ObservedObject var presetingStore: Store<InnerPresentState>
    
    public init(@ViewBuilder content: () -> Content ) {
        self.init(level: 0, content: content)
    }
    
    init(level: UInt, @ViewBuilder content: () -> Content) {
        self.level = level
        self.content = content()
        self.presetingStore = PresentState.presentStore.state.innerPresentStoreOnLevel(level, level == 0)
    }
    
    public var body: some View {
        ZStack {
            content
                .sheet(isPresented: presetingStore.binding(of: \.isPresenting)) {
                    PresentedView(level: level + 1)
                }
                #if os(iOS) || os(tvOS) || os(watchOS)
                .fullScreenCover(isPresented: presetingStore.binding(of: \.isFullCoverPresenting)) {
                    PresentedView(level: level + 1)
                }
                #endif
        }
    }
}
