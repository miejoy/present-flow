//
//  PresentRouteTests.swift
//  
//
//  Created by 黄磊 on 2022/9/29.
//

import XCTest
import ViewFlow
import SwiftUI
@testable import PresentFlow

final class PresentRouteTests: XCTestCase {
    func testRouteEqual() throws {
        let route1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId)
        let route2 = PresentRoute<Void>(routeId: s_defaultPresentRouteId)
        
        XCTAssertEqual(route1, route2)
        XCTAssertEqual(route1.description, route2.description)
    }
    
    func testAnyRouteEqual() throws {
        let route1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId)
        let anyRoute1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId).eraseToAnyRoute()
        let anyRoute2 = PresentRoute<Void>(routeId: s_defaultPresentRouteId).eraseToAnyRoute()
        
        XCTAssert(anyRoute1.equelToRoute(route1))
        XCTAssertEqual(route1.description, anyRoute1.description)
        XCTAssertEqual(anyRoute1, anyRoute2)
    }
    
    func testRouteNotEqualWithDifferentInitType() throws {
        let route1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId).eraseToAnyRoute()
        let route2 = PresentRoute<String>(routeId: s_defaultPresentRouteId).eraseToAnyRoute()
        
        XCTAssertNotEqual(route1, route2)
    }
    
    func testRouteNotEqualWithDifferentRouteId() throws {
        let route1 = PresentRoute<Void>(routeId: s_defaultPresentRouteId).eraseToAnyRoute()
        let route2 = PresentRoute<Void>(routeId: s_defaultPresentRouteId + "1").eraseToAnyRoute()
        
        XCTAssertNotEqual(route1, route2)
    }
}
