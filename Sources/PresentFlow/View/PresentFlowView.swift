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
    @InnerPresentWrapper var presetingState: InnerPresentState
    
    @Environment(\.presentManager) var presentManager
    
    public init(@ViewBuilder content: () -> Content ) {
        self.init(level: 0, content: content)
    }
    
    init(level: UInt, @ViewBuilder content: () -> Content) {
        self.level = level
        self.content = content()
        self._presetingState = .init(level)
    }
    
    public var body: some View {
        content
            .sheet(isPresented: $presetingState.binding(of: \.isPresenting)) {
                PresentedView(level: level + 1)
            }
            #if os(iOS) || os(tvOS) || os(watchOS)
            .fullScreenCover(isPresented: $presetingState.binding(of: \.isFullCoverPresenting)) {
                PresentedView(level: level + 1)
            }
            #endif
            .environment(\.presentManager, presentManager) // 减少内部使用时的调用次数
    }
}
