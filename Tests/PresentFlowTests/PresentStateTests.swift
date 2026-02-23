//
//  PresentStateTests.swift
//  
//
//  Created by 黄磊 on 2022/9/28.
//

import XCTest
@testable import DataFlow
import ViewFlow
import Combine
import SwiftUI
@testable import PresentFlow
import XCTViewFlow

import Foundation

@MainActor
final class PresentStateTests: XCTestCase {
    
    override class func setUp() {
        PresentCenter.shared.registerMap = [:]
        PresentCenter.shared.registerDefaultPresentableView(PresentThirdView.self)
        PresentCenter.shared.registerPresentableView(PresentFourthView.self, for: PresentFourthView.defaultRoute)
    }
    
    func testSaveSceneId() {
        let sceneId = SceneId.custom("SaveScene")
        
        var presentStore: Store<PresentState>? = nil
                
        struct NormalView: View {
            @Environment(\.presentManager) var presentManager
            var callback: (Store<PresentState>) -> Void
            
            var body: some View {
                callback(presentManager)
                return Text("test")
            }
        }
        
        let view = NormalView {
            presentStore = $0
        }
            .modifier(PresentModifier())
            .environment(\.sceneId, sceneId)
        
        let host = ViewTest.host(view)
        
        XCTAssertNotNil(presentStore)
        XCTAssertEqual(presentStore?.sceneId, sceneId)
        
        ViewTest.releaseHost(host)
    }
    
    func testPresentView() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentFirstView.getCall = false
        presentStore.present(PresentFirstView())
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertEqual(PresentFirstView.getCall, true)
    }
    
    func testPresentViewType() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentFirstView.getCall = false
        presentStore.present(PresentFirstView.self)
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertEqual(PresentFirstView.getCall, true)
    }
    
    func testPresentRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentThirdView.getCall = false
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssertEqual(PresentThirdView.getCall, true)
    }
    
    func testPresentAnyRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentThirdView.getCall = false
        presentStore.send(action: .present(PresentThirdView.defaultRoute.eraseToAnyRoute()))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssertEqual(PresentThirdView.getCall, true)
    }
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    
    func testPresentFullCoverView() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentFirstView.getCall = false
        presentStore.presentFullCover(PresentFirstView())
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertEqual(PresentFirstView.getCall, true)
    }
    
    func testPresentFullCoverViewType() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentFirstView.getCall = false
        presentStore.presentFullCover(PresentFirstView.self)
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertEqual(PresentFirstView.getCall, true)
    }
        
    func testPresentFullCoverRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        PresentThirdView.getCall = false
        presentStore.send(action: .present(PresentThirdView.defaultRoute, isFullCover: true))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssertEqual(PresentThirdView.getCall, true)
    }
    
    #endif
    
    func testPresentTwo() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        let secondData: String = "second"
        PresentFirstView.getCall = false
        PresentSecondView.getCall = false
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, secondData)
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        // XCTAssertEqual((presentStore.storage.innerPresentStores[2].first?.viewMaker as! PresentableViewMaker<PresentSecondView>).data, secondData)
        XCTAssertEqual(PresentFirstView.getCall, true)
        XCTAssertEqual(PresentSecondView.getCall, true)
    }
    
    func testPresentFour() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        let firstNavTitle = "FirstNavTitle"
        let thirdNavTitle = "ThirdNavTitle"
        
        PresentFirstView.getCall = false
        PresentSecondView.getCall = false
        PresentThirdView.getCall = false
        PresentFourthView.getCall = false
        presentStore.send(action: .present(PresentFirstView.self, navTitle: firstNavTitle))
        presentStore.send(action: .present(PresentSecondView.self, "", isFullCover: true))
        presentStore.send(action: .present(PresentThirdView.defaultRoute, navTitle: thirdNavTitle))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0, needFreeze: true))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        #if os(iOS) || os(tvOS) || os(watchOS)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, true)
        #else
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        #endif
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.navigationState?.navigationTitle, firstNavTitle)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        #if os(iOS) || os(tvOS) || os(watchOS)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCover, true)
        #else
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCover, false)
        #endif
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.navigationState?.navigationTitle, thirdNavTitle)
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFrozen, true)
        XCTAssertEqual(PresentFirstView.getCall, true)
        XCTAssertEqual(PresentSecondView.getCall, true)
        XCTAssertEqual(PresentThirdView.getCall, true)
        XCTAssertEqual(PresentFourthView.getCall, true)
    }
    
    func testPresentOnLevel() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
                
        // 先弹出 3 层view
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentFourthView.defaultRoute, 0)
        presentStore.present(PresentThirdView.defaultRoute)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        PresentFirstView.getCall = false
        PresentSecondView.getCall = false
        PresentThirdView.getCall = false
        PresentFourthView.getCall = false
        
        presentStore.send(action: .present(PresentSecondView.self, "", baseOnLevel: 1))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        XCTAssertEqual(PresentFirstView.getCall, false)
        XCTAssertEqual(PresentSecondView.getCall, true)
        XCTAssertEqual(PresentThirdView.getCall, false)
        XCTAssertEqual(PresentFourthView.getCall, false)
    }
    
    func testPresentOnLevelWithRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
                
        // 先弹出 3 层view
        presentStore.present(PresentFirstView.self)
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        PresentFirstView.getCall = false
        PresentSecondView.getCall = false
        PresentThirdView.getCall = false
        PresentFourthView.getCall = false
        
        presentStore.send(action: .present(PresentThirdView.defaultRoute, baseOnLevel: 1))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssertEqual(PresentFirstView.getCall, false)
        XCTAssertEqual(PresentSecondView.getCall, false)
        XCTAssertEqual(PresentThirdView.getCall, true)
        XCTAssertEqual(PresentFourthView.getCall, false)
    }
    
    func testPresentOnRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
                
        // 先弹出 3 层 view
        presentStore.present(PresentFirstView.self)
        presentStore.send(action: .present(PresentSecondView.self, ""))
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        PresentFirstView.getCall = false
        PresentSecondView.getCall = false
        PresentThirdView.getCall = false
        PresentFourthView.getCall = false
        
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0, baseOnRoute: PresentFirstView.defaultRoute))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssertEqual(PresentFirstView.getCall, false)
        XCTAssertEqual(PresentSecondView.getCall, false)
        XCTAssertEqual(PresentThirdView.getCall, false)
        XCTAssertEqual(PresentFourthView.getCall, true)
    }
    
    func testPresentOnRouteWithView() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
                
        // 先弹出 3 层 view
        presentStore.present(PresentFirstView.self)
        presentStore.send(action: .present(PresentFourthView.self, 0))
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        presentStore.send(action: .present(PresentSecondView.self, "", baseOnRoute: PresentFirstView.defaultRoute))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
    }
    
    func testPresentOnRouteWithVoidView() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
                
        // 先弹出 3 层 view
        presentStore.present(PresentFirstView.self)
        presentStore.send(action: .present(PresentFourthView.self, 0))
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        presentStore.send(action: .present(PresentFirstView.self, baseOnRoute: PresentFirstView.defaultRoute))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
    }
    
    func testPresentOnRouteWithVoidRoute() throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
                
        // 先弹出 3 层 view
        presentStore.present(PresentFirstView.self)
        presentStore.send(action: .present(PresentFourthView.self, 0))
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        presentStore.send(action: .present(PresentThirdView.defaultRoute, baseOnRoute: PresentFirstView.defaultRoute))
        
        // 判断 各层状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)

        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? RegisteredPresentableViewMaker)
    }
    
    func testPresentOnNotFound() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        PresentMonitor.shared.arrObservers = []
        class Observer: PresentMonitorObserver, @unchecked Sendable {
            var presentRoute: AnyViewRoute? = nil
            var presentOnNotFound: TargetRouteNotFound? = nil
            func receivePresentEvent(_ event: PresentEvent) {
                if case .presentFailed(let presentRoute, let notFound)  = event {
                    self.presentRoute = presentRoute
                    self.presentOnNotFound = notFound
                }
            }
        }
        let observer = Observer()
        let cancellable = PresentMonitor.shared.addObserver(observer)
        
        XCTAssertNil(observer.presentRoute)
        XCTAssertNil(observer.presentOnNotFound)
        presentStore.send(action: .present(PresentFourthView.self, 0, baseOnLevel: 4))
        XCTAssertNotNil(observer.presentRoute)
        XCTAssertNotNil(observer.presentOnNotFound)
        XCTAssertEqual(observer.presentRoute, PresentFourthView.defaultRoute.eraseToAnyRoute())
        XCTAssertEqual(observer.presentOnNotFound, .level(4))
        
        observer.presentRoute = nil
        observer.presentOnNotFound = nil
        presentStore.send(action: .present(PresentFourthView.self, 0, baseOnRoute: PresentFourthView.defaultRoute))
        XCTAssertNotNil(observer.presentRoute)
        XCTAssertNotNil(observer.presentOnNotFound)
        XCTAssertEqual(observer.presentRoute, PresentFourthView.defaultRoute.eraseToAnyRoute())
        XCTAssertEqual(observer.presentOnNotFound, .route(PresentFourthView.defaultRoute.eraseToAnyRoute()))
        
        cancellable.cancel()
    }
    
    func testDismiss() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        
        presentStore.dismissTopView()
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)        
    }
    
    func testDismissToRoot() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        
        presentStore.dismissToRootView()
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
    }
    
    func testDismissToLevel() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Void)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Int)
        
        presentStore.send(action: .dismissToViewOnLevel(1))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
    }
    
    func testDismissToRoute() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Void)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Int)
        
        presentStore.send(action: .dismissToViewOnRoute(PresentSecondView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
    }
    
    func testDismissViewOnLevel() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Void)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Int)
        
        presentStore.dismissViewOnLevel(2)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
    }
    
    func testDismissViewOnRoute() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        
        // 判断 中间状态
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[1].first?.viewMaker as? PresentableViewMaker<PresentFirstView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[2].first?.viewMaker as? PresentableViewMaker<PresentSecondView>)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[3].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Void)
        XCTAssertNotNil(presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)
        XCTAssert((presentStore.storage.innerPresentStores[4].first?.viewMaker as? RegisteredPresentableViewMaker)?.initData is Int)
        
        presentStore.send(action: .dismissViewOnRoute(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)

        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFullCoverPresenting, false)
        
        presentStore.send(action: .dismissViewOnRoute(PresentSecondView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, false)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].count, 1)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isPresenting, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFullCoverPresenting, false)
    }
    
    func testDismissNotFound() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        PresentMonitor.shared.arrObservers = []
        class Observer: PresentMonitorObserver, @unchecked Sendable {
            var dismissNotFound: TargetRouteNotFound? = nil
            func receivePresentEvent(_ event: PresentEvent) {
                if case .dismissFailed(let notFound)  = event {
                    dismissNotFound = notFound
                }
            }
        }
        let observer = Observer()
        let cancellable = PresentMonitor.shared.addObserver(observer)
        
        XCTAssertNil(observer.dismissNotFound)
        presentStore.send(action: .dismissViewOnLevel(4))
        XCTAssertNotNil(observer.dismissNotFound)
        XCTAssertEqual(observer.dismissNotFound, TargetRouteNotFound.level(4))
        
        observer.dismissNotFound = nil
        presentStore.send(action: .dismissViewOnRoute(PresentFourthView.defaultRoute))
        XCTAssertNotNil(observer.dismissNotFound)
        XCTAssertEqual(observer.dismissNotFound, TargetRouteNotFound.route(PresentFourthView.defaultRoute.eraseToAnyRoute()))
        
        cancellable.cancel()
    }
    
    func testUserDismiss() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 4)
        
        presentStore.storage.innerPresentStores[2].first?.isPresenting = false
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 3)
    }
    
    func testFreeze() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        presentStore.send(action: .present(PresentFourthView.defaultRoute, 0))
        
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 5)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[1].first?.isFrozen, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFrozen, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFrozen, false)
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFrozen, false)
        
        // Freeze
        presentStore.send(action: .freezeTopView())
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFrozen, true)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFrozen, false)
        presentStore.send(action: .freezeViewOnLevel(2))
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFrozen, true)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFrozen, false)
        presentStore.send(action: .freezeViewOnRoute(PresentThirdView.defaultRoute))
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFrozen, true)
        
        // Unfreeze
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFrozen, true)
        presentStore.send(action: .unfreezeTopView())
        XCTAssertEqual(presentStore.storage.innerPresentStores[4].first?.isFrozen, false)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFrozen, true)
        presentStore.send(action: .unfreezeViewOnLevel(2))
        XCTAssertEqual(presentStore.storage.innerPresentStores[2].first?.isFrozen, false)
        
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFrozen, true)
        presentStore.send(action: .unfreezeViewOnRoute(PresentThirdView.defaultRoute))
        XCTAssertEqual(presentStore.storage.innerPresentStores[3].first?.isFrozen, false)
    }
    
    func testFreezeNotFound() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let view = FakeRootView(store: presentStore)
        XCTAssertTrue(view.store === presentStore)
        
        presentStore.present(PresentFirstView.self)
        presentStore.present(PresentSecondView.self, "")
        presentStore.send(action: .present(PresentThirdView.defaultRoute))
        
        PresentMonitor.shared.arrObservers = []
        class Observer: PresentMonitorObserver, @unchecked Sendable {
            var freezeNotFound: TargetRouteNotFound? = nil
            var unfreezeNotFound: TargetRouteNotFound? = nil
            func receivePresentEvent(_ event: PresentEvent) {
                if case .freezeFailed(let notFound)  = event {
                    freezeNotFound = notFound
                } else if case .unfreezeFailed(let notFound) = event {
                    unfreezeNotFound = notFound
                }
            }
        }
        let observer = Observer()
        let cancellable = PresentMonitor.shared.addObserver(observer)
        
        XCTAssertNil(observer.freezeNotFound)
        presentStore.send(action: .freezeViewOnLevel(4))
        XCTAssertNotNil(observer.freezeNotFound)
        XCTAssertEqual(observer.freezeNotFound, TargetRouteNotFound.level(4))
        
        XCTAssertNil(observer.unfreezeNotFound)
        presentStore.send(action: .unfreezeViewOnRoute(PresentFourthView.defaultRoute))
        XCTAssertNotNil(observer.unfreezeNotFound)
        XCTAssertEqual(observer.unfreezeNotFound, TargetRouteNotFound.route(PresentFourthView.defaultRoute.eraseToAnyRoute()))
        
        cancellable.cancel()
    }
}


class FakePresentedView {
    var sceneId: SceneId
    var level: UInt
    var store: Store<PresentState>
    var innerStore: Store<InnerPresentState>
    var presentedView: FakePresentedView? = nil
    var presentingObserver: AnyCancellable? = nil
    var fullCoverPresentingObserver: AnyCancellable? = nil
    
    @MainActor
    init(sceneId: SceneId, level: UInt, store: Store<PresentState>) {
        self.sceneId = sceneId
        self.level = level
        self.store = store
        self.innerStore = store.innerPresentStoreOnLevel(level, level == 0)
        self.presentingObserver = self.innerStore.addObserver(of: \.isPresenting) { [weak self] new, old in
            guard let self = self else {
                return
            }
            if new {
                self.presentedView = FakePresentedView(sceneId: self.sceneId, level: self.level + 1, store: self.store)
            } else {
                if let presentedView = self.presentedView {
                    presentedView.store.apply(action: .didDisappearOnLevel(presentedView.level))
                }
            }
        }
        self.fullCoverPresentingObserver = self.innerStore.addObserver(of: \.isFullCoverPresenting) { [weak self] new, old in
            guard let self = self else {
                return
            }
            if new {
                self.presentedView = FakePresentedView(sceneId: self.sceneId, level: self.level + 1, store: self.store)
            } else {
                if let presentedView = self.presentedView {
                    presentedView.store.apply(action: .didDisappearOnLevel(presentedView.level))
                }
            }
        }
        
        // 这里调用之后，理论上会构造对应 View
        _ = self.innerStore.state.makeView(sceneId, AnyView(EmptyView()))
        if level > 0 {
            self.store.apply(action: .didAppearOnLevel(self.level))
        }
//        AnyView._makeView(view: view, inputs: view)
    }
}

class FakeRootView {
    var store: Store<PresentState>
    
    var presentedView: FakePresentedView
    
    @MainActor
    init(store: Store<PresentState>) {
        self.store = store
        self.presentedView = FakePresentedView(sceneId: .main, level: 0, store: store)
    }
}

struct PresentFirstView: VoidPresentableView {
    static var getCall: Bool = false
    init() {
        Self.getCall = true
    }
    var content: some View {
        Text("First View")
    }
}

struct PresentSecondView: PresentableView {
    static var getCall: Bool = false
    var string: String
    init(_ data: String) {
        Self.getCall = true
        self.string = data
    }
    var content: some View {
        Text("Second View")
    }
}

struct PresentThirdView: VoidPresentableView {
    static var getCall: Bool = false
    init() {
        Self.getCall = true
    }
    var content: some View {
        Text("Third View")
    }
}

struct PresentFourthView: PresentableView {
    static var getCall: Bool = false
    var int: Int
    init(_ data: Int) {
        self.int = data
        Self.getCall = true
    }
    var content: some View {
        Text("Fourth View")
    }
}
