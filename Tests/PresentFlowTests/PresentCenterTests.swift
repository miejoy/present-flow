//
//  PresentCenterTests.swift
//  
//
//  Created by 黄磊 on 2022/10/1.
//

import XCTest
import DataFlow
import ViewFlow
import SwiftUI
@testable import PresentFlow
import XCTViewFlow

final class PresentCenterTests: XCTestCase {
    func testRouteRegister() throws {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        let route1 = ViewRoute<Void>(routeId: s_defaultViewRouteId)
        let route2 = ViewRoute<Void>(routeId: s_defaultViewRouteId)
        let route3 = ViewRoute<Void>(routeId: "default")
        
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
        
        let secondRoute = ViewRoute<String>(routeId: "second")
        presentCenter.registePresentableView(PresentSecondView.self, for: secondRoute)
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[AnyHashable(secondRoute)])
    }
    
    func testRegisterOnView() {
        let sceneId = SceneId.custom("otherScene")
        
        let presentStore = Store<PresentState>.shared(on: sceneId)
        presentStore.presentCenter.registerMap = [:]
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 0)
        
        let host = ViewTest.host(Color.red.registerPresentableView(PresentFirstView.self, for: PresentFirstView.defaultRoute).environment(\.sceneId, sceneId))
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentStore.presentCenter.registerMap[AnyHashable(PresentFirstView.defaultRoute)])
        
        ViewTest.releaseHost(host)
    }
    
    func testRegisterWithPresentCenterOnView() {
        let sceneId = SceneId.custom("otherScene1")
        
        let presentStore = Store<PresentState>.shared(on: sceneId)
        presentStore.presentCenter.registerMap = [:]
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 0)
        
        let host = ViewTest.host(Color.red.registerPresentOn({ presentCenter in
            presentCenter.registeDefaultPresentableView(PresentFirstView.self)
            presentCenter.registeDefaultPresentableView(PresentSecondView.self)
        }).environment(\.sceneId, sceneId))
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentStore.presentCenter.registerMap[AnyHashable(PresentFirstView.defaultRoute)])
        XCTAssertNotNil(presentStore.presentCenter.registerMap[AnyHashable(PresentSecondView.defaultRoute)])
        
        ViewTest.releaseHost(host)
    }
    
    func testRegisterPresentedModifier() {
        let sceneId = SceneId.custom("otherScene1")
        
        var callbackSceneId: SceneId? = nil
        var callbackLevel: UInt? = nil
        
        let view = PresentedModifiterTestView {
            callbackSceneId = $0
            callbackLevel = $1
        }
        
        let host = ViewTest.host(view.environment(\.sceneId, sceneId))
        
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callbackSceneId, sceneId)
        XCTAssertEqual(callbackLevel, 1)
        
        ViewTest.releaseHost(host)
    }
}



struct PresentedModifiterTestView: View {
    
    let callback: (_ sceneId: SceneId, _ level: UInt) -> Void
    
    var body: some View {
        PresentFlowView {
            PresentTextView()
        }
        .registerPresentedModifier { (content, sceneId, level) -> AnyView in
            callback(sceneId, level)
            return content
        }
        .registerPresentableView(PresentFirstView.self)
    }
}

struct PresentTextView: View {
    
    @Environment(\.presentManager) var presentManager
    
    var body: some View {
        Text("text")
            .onAppear {
                presentManager.present(PresentFirstView.self)
            }
    }
}
