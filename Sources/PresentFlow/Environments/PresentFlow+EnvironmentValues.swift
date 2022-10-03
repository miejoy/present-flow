//
//  PresentFlow+EnvironmentValues.swift
//  
//
//  Created by 黄磊 on 2022/8/7.
//

import SwiftUI
import DataFlow
import ViewFlow

extension EnvironmentValues {
    /// 展示管理器
    public var presentManager: Store<PresentState> {
        get { self[PresentStoreKey.self] }
        set { self[PresentStoreKey.self] = newValue }
    }
    
    /// 展示的层级，从 0 开始
    internal(set) public var presentLevel: UInt {
        get { self[PresentLevelKey.self] }
        set { self[PresentLevelKey.self] = newValue }
    }
    
    /// 展示的层级，从 0 开始
    public var presentedCloseView: AnyView {
        get { self[PresentedCloseViewKey.self] }
        set { self[PresentedCloseViewKey.self] = newValue }
    }
}

/// 展示存储器对应的 key
struct PresentStoreKey: EnvironmentKey {
    static var defaultValue: Store<PresentState> {
        SceneSharedState<PresentState>().projectedValue
    }
}

/// 展示的层级
struct PresentLevelKey: EnvironmentKey {
    static var defaultValue: UInt = 0
}

/// 展示的界面导航关闭按钮
struct PresentedCloseViewKey: EnvironmentKey {
    static var defaultValue: AnyView = AnyView(Image(systemName: "multiply.circle.fill").foregroundColor(Color.gray)
        .frame(width: 30, height: 44))
}
