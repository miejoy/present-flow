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
        
        presentCenter.registerMap[route1.eraseToAnyRoute()] = .init(PresentFirstView.self)
        
        let maker2 = presentCenter.registerMap[route2.eraseToAnyRoute()]
        XCTAssertNotNil(maker2)
        
        let maker3 = presentCenter.registerMap[route3.eraseToAnyRoute()]
        XCTAssertNil(maker3)
    }
    
    func testRegisterWithView() {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        
        presentCenter.registerDefaultPresentableView(PresentFirstView.self)
        XCTAssertEqual(presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentCenter.registerMap[PresentFirstView.defaultRoute.eraseToAnyRoute()])
        
        presentCenter.registerDefaultPresentableView(PresentSecondView.self)
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[PresentSecondView.defaultRoute.eraseToAnyRoute()])
    }
    
    func testRegisterWithRoute() {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        
        presentCenter.registerPresentableView(PresentFirstView.self, for: PresentThirdView.defaultRoute)
        XCTAssertEqual(presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentCenter.registerMap[PresentThirdView.defaultRoute.eraseToAnyRoute()])
        
        let secondRoute = ViewRoute<String>(routeId: "second")
        presentCenter.registerPresentableView(PresentSecondView.self, for: secondRoute)
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[secondRoute.eraseToAnyRoute()])
    }
    
    func testRegisterOnView() {
        let sceneId = SceneId.custom("otherScene")
        
        let presentStore = Store<PresentState>.shared(on: sceneId)
        presentStore.presentCenter.registerMap = [:]
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 0)
        
        let host = ViewTest.host(Color.red.registerPresentableView(PresentFirstView.self, for: PresentFirstView.defaultRoute).environment(\.sceneId, sceneId))
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentStore.presentCenter.registerMap[PresentFirstView.defaultRoute.eraseToAnyRoute()])
        
        ViewTest.releaseHost(host)
    }
    
    func testRegisterWithPresentCenterOnView() {
        let sceneId = SceneId.custom("otherScene1")
        
        let presentStore = Store<PresentState>.shared(on: sceneId)
        presentStore.presentCenter.registerMap = [:]
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 0)
        
        let host = ViewTest.host(Color.red.registerPresentOn({ presentCenter in
            presentCenter.registerDefaultPresentableView(PresentFirstView.self)
            presentCenter.registerDefaultPresentableView(PresentSecondView.self)
        }).environment(\.sceneId, sceneId))
        
        XCTAssertEqual(presentStore.presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentStore.presentCenter.registerMap[PresentFirstView.defaultRoute.eraseToAnyRoute()])
        XCTAssertNotNil(presentStore.presentCenter.registerMap[PresentSecondView.defaultRoute.eraseToAnyRoute()])
        
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
    
    func testRegisterExternalViewMaker() {
        
        PresentCenter.shared.externalViewMaker = nil
        let sceneId = SceneId.custom("otherScene2")
        
        let route = ViewRoute<Int>(routeId: "EmptyView")
        let data: Int = 1
        var callRouteData: ViewRouteData? = nil
        
        PresentCenter.shared.registerExternalViewMaker { routeData, sceneId in
            callRouteData = routeData
            return AnyView(EmptyView())
        }
        
        XCTAssertNotNil(PresentCenter.shared.externalViewMaker)
        
        let view = Text("test")
            .modifier(PresentModifier())
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(route.wrapper(data))
            }
            .environment(\.sceneId, sceneId)
        
        let host = ViewTest.host(view)
        
        XCTAssertNil(callRouteData)
        
        // 这里才会真正展示新界面
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callRouteData?.route, route.eraseToAnyRoute())
        XCTAssertEqual(callRouteData?.initData as? Int, data)
        
        PresentCenter.shared.externalViewMaker = nil
    }
    
    func testRegisterExternalViewMakerOnScene() {
        let sceneId = SceneId.custom("otherScene3")
        
        let route = ViewRoute<Int>(routeId: "EmptyView")
        let data: Int = 1
        var callRouteData: ViewRouteData? = nil
        
        let view = Text("test")
            .modifier(PresentModifier())
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(route.wrapper(data))
            }
            .registerPresentOn { presentCenter in
                presentCenter.registerExternalViewMaker { routeData, sceneId in
                    callRouteData = routeData
                    return AnyView(EmptyView())
                }
            }
            .environment(\.sceneId, sceneId)
        
        let host = ViewTest.host(view)
        
        XCTAssertNil(callRouteData)
        
        // 这里才会真正展示新界面
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callRouteData?.route, route.eraseToAnyRoute())
        XCTAssertEqual(callRouteData?.initData as? Int, data)
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
