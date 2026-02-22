//
//  PresentedView.swift
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
        // 这里 SwiftUI 的 onAppear 调用过早，目前只能借用 UIViewController 的 viewDidAppear
        .onAppeared {
            if presentManager.storage.innerPresentStores.count > level
                && presentManager.curLevel != level {
                presentManager.apply(action: .didAppearOnLevel(level))
            }
        }
        .onDisappear {
            // 这里需要读取 上一层 presentingStore 是否真的不展示了，避免多销毁了 store。
            // 在展示全屏的 UIViewController 时，最上层的 SwiftUI 界面都会 Disapper
            let presentingStore = presentManager.innerPresentStoreOnLevel(level - 1)
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


extension View {
    /// 在界面已经出现时调用，并且只调用一次
    public func onAppeared(perform action: (() -> Void)? = nil ) -> some View {
        #if canImport(UIKit)
        self.overlay(UIKitAppeared(onAppeared: action).disabled(true))
        #else
        self.overlay(EmptyView())
        #endif
    }
}


#if canImport(UIKit)
private struct UIKitAppeared: UIViewControllerRepresentable {
    let onAppeared: (() -> Void)?

    func makeUIViewController(context: Context) -> AppearedViewController {
        let vc = AppearedViewController()
        vc.onAppeared = onAppeared
        return vc
    }

    func updateUIViewController(_ controller: AppearedViewController, context: Context) {}

    class AppearedViewController: UIViewController {
        var onAppeared: (() -> Void)? = nil
        var callBefore: Bool = false

        override func viewDidAppear(_ animated: Bool) {
            if !callBefore {
                callBefore = true
                onAppeared?()
            }
        }
    }
}
#endif // canImport(UIKit)
