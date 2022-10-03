//
//  PresentableViewMaker.swift
//  
//
//  Created by 黄磊 on 2022/9/12.
//

import Foundation
import SwiftUI

struct PresentableViewMaker<P: PresentableView> : PresentedViewMaker {
    var data: P.InitData
    
    func makeView() -> AnyView {
        return AnyView(P(data))
    }
}
