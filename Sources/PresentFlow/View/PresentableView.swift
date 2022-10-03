//
//  PresentableView.swift
//  
//
//  Created by 黄磊 on 2022/8/2.
//

import ViewFlow
import SwiftUI

/// 可用于展示的界面，需要展示的 View 都需要基础这个协议
public protocol PresentableView: TrackableView, InitializableView {
}

public protocol VoidPresentableView: PresentableView, VoidInitializableView {
}

extension PresentableView {
    @inlinable
    public static var defaultRoute: PresentRoute<InitData> { .init(routeId: String(describing: Self.self)) }
}
