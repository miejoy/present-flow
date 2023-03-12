//
//  PresentModifier.swift
//  
//
//  Created by 黄磊 on 2022/8/27.
//

import Foundation
import DataFlow
import SwiftUI

/// 展示修改器
public struct PresentModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        PresentFlowView {
            content
        }
    }
}
