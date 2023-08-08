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
    
    let defaultViewRouteId: String = "__default__"
    
    func testRouteRegister() throws {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        let route1 = ViewRoute<String>(defaultViewRouteId)
        let route2 = ViewRoute<String>(defaultViewRouteId)
        let route3 = ViewRoute<String>("default")
        
        presentCenter.registerMap[route1.eraseToAnyRoute()] = .init(PresentSecondView.self)
        
        let maker2 = presentCenter.registerMap[route2.eraseToAnyRoute()]
        XCTAssertNotNil(maker2)
        
        let maker3 = presentCenter.registerMap[route3.eraseToAnyRoute()]
        XCTAssertNil(maker3)
    }
    
    func testVoidRouteRegister() throws {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        let route1 = ViewRoute<Void>(defaultViewRouteId)
        let route2 = ViewRoute<Void>(defaultViewRouteId)
        let route3 = ViewRoute<Void>("default")
        
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
        
        let secondRoute = ViewRoute<String>("second")
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
        
        PresentCenter.shared.externalManager = nil
        let sceneId = SceneId.custom("otherScene2")
        
        let route = ViewRoute<Int>("EmptyView")
        let data: Int = 1
        var callRouteData: ViewRouteData? = nil
        
        PresentCenter.shared.registerExternalViewMaker { routeData, sceneId in
            callRouteData = routeData
            return AnyView(EmptyView())
        }
        
        XCTAssertNotNil(PresentCenter.shared.externalManager)
        
        let view = Text("test")
            .modifier(PresentModifier())
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(route.wrapper(data))
            }
            .environment(\.sceneId, sceneId)
        
        XCTAssertNil(callRouteData)
        
        let host = ViewTest.host(view)
        
        // 这里才会真正展示新界面
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callRouteData?.route, route.eraseToAnyRoute())
        XCTAssertEqual(callRouteData?.initData as? Int, data)
        
        ViewTest.releaseHost(host)
        
        PresentCenter.shared.externalManager = nil
    }
    
    func testRegisterExternalViewMakerOnScene() {
        let sceneId = SceneId.custom("otherScene3")
        
        let route = ViewRoute<Int>("EmptyView")
        let data: Int = 1
        var callRouteData: ViewRouteData? = nil
        
        let view = Text("test")
            .modifier(PresentModifier())
            .registerPresentOn { presentCenter in
                presentCenter.registerExternalViewMaker { routeData, sceneId in
                    callRouteData = routeData
                    return AnyView(EmptyView())
                }
            }
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(route.wrapper(data))
            }
            .environment(\.sceneId, sceneId)
        
        XCTAssertNil(callRouteData)
        
        let host = ViewTest.host(view)        
        
        // 这里才会真正展示新界面
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callRouteData?.route, route.eraseToAnyRoute())
        XCTAssertEqual(callRouteData?.initData as? Int, data)
    }
    
    func testRegisterExternalViewMakerAndModifier() {
        
        PresentCenter.shared.externalManager = nil
        let sceneId = SceneId.custom("otherScene4")
        
        let route = ViewRoute<Int>("EmptyView")
        let data: Int = 1
        var callRouteData: ViewRouteData? = nil
        var callModifierRoute: AnyViewRoute? = nil
        
        PresentCenter.shared.registerExternalViewMaker { routeData, sceneId in
            callRouteData = routeData
            return AnyView(EmptyView())
        } modifier: { route, sceneId, view in
            callModifierRoute = route
            return view
        }
        
        XCTAssertNotNil(PresentCenter.shared.externalManager)
        
        let view = Text("test")
            .modifier(PresentModifier())
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(route.wrapper(data))
            }
            .environment(\.sceneId, sceneId)
        
        XCTAssertNil(callRouteData)
        
        let host = ViewTest.host(view)
        
        // 这里才会真正展示新界面
        ViewTest.refreshHost(host)
        
        XCTAssertEqual(callRouteData?.route, route.eraseToAnyRoute())
        XCTAssertEqual(callRouteData?.initData as? Int, data)
        XCTAssertEqual(callModifierRoute, route.eraseToAnyRoute())
        
        ViewTest.releaseHost(host)
        
        PresentCenter.shared.externalManager = nil
    }
    
    func testRegisterWithModifier() {
        PresentCenter.shared.registerMap = [:]
        let presentCenter = PresentCenter.shared
        
        var modifier1GetCall = false
        presentCenter.registerDefaultPresentableView(PresentFirstView.self) { view in
            modifier1GetCall = true
            return view
        }
        
        XCTAssertEqual(presentCenter.registerMap.count, 1)
        XCTAssertNotNil(presentCenter.registerMap[PresentFirstView.defaultRoute.eraseToAnyRoute()])
        
        var modifier2GetCall = false
        presentCenter.registerDefaultPresentableView(PresentSecondView.self) { view in
            modifier2GetCall = true
            return view
        }
        XCTAssertEqual(presentCenter.registerMap.count, 2)
        XCTAssertNotNil(presentCenter.registerMap[PresentSecondView.defaultRoute.eraseToAnyRoute()])
        
        if let viewMaker = presentCenter.registerMap[PresentFirstView.defaultRoute.eraseToAnyRoute()] {
            XCTAssertFalse(modifier1GetCall)
            _ = viewMaker.modifier(AnyView(EmptyView()))
            XCTAssertTrue(modifier1GetCall)
        }
        
        if let viewMaker = presentCenter.registerMap[PresentSecondView.defaultRoute.eraseToAnyRoute()] {
            XCTAssertFalse(modifier2GetCall)
            _ = viewMaker.modifier(AnyView(EmptyView()))
            XCTAssertTrue(modifier2GetCall)
        }
    }
    
    func testRegisterWithModifierOnView() {
        PresentCenter.shared.registerMap = [:]
        
        let sceneId = SceneId.custom("otherScene5")
        
        var modifierGetCall = false
        
        let view = Text("test")
            .modifier(PresentModifier())
            .registerPresentOn { presentCenter in
                presentCenter.registerDefaultPresentableView(PresentFirstView.self) { view in
                    modifierGetCall = true
                    return view
                }
            }
            .onAppear {
                Store<PresentState>.shared(on: sceneId).present(PresentFirstView.defaultRoute)
            }
            .environment(\.sceneId, sceneId)
        
        XCTAssertFalse(modifierGetCall)
        
        let host = ViewTest.host(view)
                
        // 这里才会真正展示新界面，这里目前没有用
        ViewTest.refreshHost(host)
        
        XCTAssertTrue(modifierGetCall)
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
