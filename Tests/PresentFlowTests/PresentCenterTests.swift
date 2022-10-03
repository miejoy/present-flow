//
//  PresentCenterTests.swift
//  
//
//  Created by 黄磊 on 2022/10/1.
//

import XCTest
import ViewFlow
import SwiftUI
@testable import PresentFlow

final class PresentCenterTests: XCTestCase {
    func testRouteRegister() throws {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        let route1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId)
        let route2 = PresentRoute<Void>(routeId: s_defaultPresentRouteId)
        let route3 = PresentRoute<Void>(routeId: "default")
        
        presentCenter.registerMap[AnyHashable(route1)] = .init(PresentFirstView.self)
        
        let maker2 = presentCenter.registerMap[AnyHashable(route2)]
        XCTAssertNotNil(maker2)
        
        let maker3 = presentCenter.registerMap[AnyHashable(route3)]
        XCTAssertNil(maker3)
    }
    
    func testRegisterWithView() {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        
        presentCenter.registeDefaultPresentableView(PresentFirstView.self)
        XCTAssertEqual(presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentCenter.registerMap[AnyHashable(PresentFirstView.defaultRoute)])
        
        presentCenter.registeDefaultPresentableView(PresentSecondView.self)
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[AnyHashable(PresentSecondView.defaultRoute)])
    }
    
    func testRegisterWithRoute() {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        
        presentCenter.registePresentableView(PresentFirstView.self, for: PresentThirdView.defaultRoute)
        XCTAssertEqual(presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentCenter.registerMap[AnyHashable(PresentThirdView.defaultRoute)])
        
        let secondRoute = PresentRoute<String>(routeId: "second")
        presentCenter.registePresentableView(PresentSecondView.self, for: secondRoute)
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[AnyHashable(secondRoute)])
    }
}

