//
//  File.swift
//  
//
//  Created by 黄磊 on 2022/8/7.
//

import SwiftUI
import DataFlow
import ViewFlow

/// 展示中的界面，内部使用，主要是对展示的界面的包装
struct PresentedView: TrackableView {
    
    let level: UInt
    @Environment(\.presentManager) var presentManager

    @Environment(\.sceneId) var sceneId
    /// 关闭按钮
    @Environment(\.presentedCloseView) var closeView
    
    @InnerPresentWrapper var presetedState: InnerPresentState
    
    init(level: UInt) {
        self.level = level
        self._presetedState = .init(level)
    }
    
    var content: some View {
        PresentFlowView(level: level) {
            presetedState.makeView(sceneId, closeView)
        }
        .modifier(PresentedModifier(
            callback: presentManager.presentCenter.presentedModifier ?? PresentCenter.shared.presentedModifier)
        )
        .interactiveDismissDisabled(presetedState.isFrozen)
        .onDisappear {
            // 这里需要确保是异步的
            presentManager.apply(action: .didDisappearOnLevel(level))
        }
        .environment(\.presentLevel, level)
    }
    
    var trackId: String {
        "\(String(describing: Self.self))-\(level)"
    }
}
