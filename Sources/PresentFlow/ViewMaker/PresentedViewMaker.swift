//
//  File.swift
//  
//
//  Created by 黄磊 on 2022/9/4.
//

import SwiftUI

/// 展示界面的包装器，暂时内部使用
protocol PresentedViewMaker {
    func makeView() -> AnyView
}

extension EmptyView: PresentedViewMaker {
    func makeView() -> AnyView {
        .init(self)
    }
}
