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
        .onAppear {
            if presentManager.state.storage.innerPresentStores.count > level
                && presentManager.curLevel != level {
                presentManager.apply(action: .didAppearOnLevel(level))
            }
        }
        .onDisappear {
            // 这里需要读取 上一层 presentingStore 是否真的不展示了，避免多销毁了 store。
            // 在展示全屏的 UIViewController 时，最上层的 SwiftUI 界面都会 Disapper
            let presentingStore = presentManager.state.innerPresentStoreOnLevel(level - 1)
            if !(presentingStore.isPresenting || presentingStore.isFullCoverPresenting) {
                presentManager.apply(action: .didDisappearOnLevel(level))
            }
        }
        .environment(\.presentLevel, level)
    }
    
    var trackId: String {
        "\(String(describing: Self.self))-\(level)"
    }
}
