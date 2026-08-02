//
//  PresentFlowResultTests.swift
//  present-flow
//
//  可返回结果路由测试
//

import XCTest
import DataFlow
import ViewFlow
import SwiftUI
import Combine
@testable import PresentFlow

@MainActor
final class PresentFlowResultTests: XCTestCase {

    override class func setUp() {
        PresentCenter.shared.registerMap = [:]
        PresentCenter.shared.registerDefaultPresentableView(ResultPickerView.self)
        PresentCenter.shared.registerDefaultPresentableView(VoidResultPickerView.self)
        PresentCenter.shared.registerDefaultPresentableView(VoidInitStringResultPickerView.self)
    }

    // MARK: - 基本行为（不依赖 FakeRootView）

    func testFinishThenCancelIsIdempotent() {
        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        routeData.finishRoute("done")
        routeData.cancelRoute()
        routeData.failRoute(reason: "test")
        XCTAssertEqual(received, .finished("done"))
    }

    func testCancelThenFinishIsIdempotent() {
        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        routeData.cancelRoute()
        routeData.finishRoute("done")
        XCTAssertEqual(received, .cancelled)
    }

    func testDeinitFiresCancelled() {
        nonisolated(unsafe) var received: ViewResult<String>?
        do {
            let routeData = ResultableRouteData<String, String>("init") { result in
                received = result
            }
            _ = routeData
        }
        XCTAssertEqual(received, .cancelled)
    }

    // MARK: - ResultViewRoute wrapper / 相等性

    func testWrapperProducesResultableRouteData() {
        let route = ResultViewRoute<String, String>("Picker")
        let inner = ResultableRouteData<String, String>("init") { _ in }
        let routeData = route.wrapper(inner)
        XCTAssertNotNil(routeData.initData as? ResultableRouteData<String, String>)
    }

    func testResultViewRouteEqualToSameType() {
        let r1 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        let r2 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        XCTAssertEqual(r1, r2)
    }

    func testResultViewRouteDifferentResultDataNotEqual() {
        let r1 = ResultViewRoute<String, Int>("Picker").eraseToAnyRoute()
        let r2 = ResultViewRoute<String, String>("Picker").eraseToAnyRoute()
        XCTAssertNotEqual(r1, r2)
    }

    // MARK: - reducer 挂钩：present 未注册路由 → failRoute

    func testPresentUnregisteredRouteFails() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let route = ResultViewRoute<String, String>("UnregisteredRoute")
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(route.wrapper(routeData)))

        // 路由未注册 → canMakeView 返回 false → failRoute
        guard case .failed = received else {
            XCTFail("Expected .failed, got \(String(describing: received))")
            return
        }
    }

    // MARK: - reducer 挂钩：present 基于不存在的 level → failRoute

    func testPresentOnInvalidLevelFails() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData), baseOnLevel: 5))

        guard case .failed = received else {
            XCTFail("Expected .failed, got \(String(describing: received))")
            return
        }
    }

    // MARK: - reducer 挂钩：present 成功 + finishRoute

    func testPresentSuccessThenFinish() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData)))

        // present 成功：level 0 正在展示，level 1 已创建
        XCTAssertEqual(presentStore.storage.innerPresentStores.count, 2)
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertNil(received) // 还没 finishRoute

        // 模拟界面 finishRoute
        routeData.finishRoute("picked")
        XCTAssertEqual(received, .finished("picked"))

        // 模拟界面消失（isPresenting = false），cancelRoute 不影响已 finish 的结果
        presentStore.storage.innerPresentStores[0].first?.isPresenting = false
        XCTAssertEqual(received, .finished("picked"))
    }

    // MARK: - reducer 挂钩：界面消失 → cancelRoute（用户滑动消失）

    func testDismissTriggersCancelRoute() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData)))

        // present 成功：level 0 正在展示
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertNil(received)

        // 模拟用户消失界面（同 testUserDismiss 的方式）
        presentStore.storage.innerPresentStores[0].first?.isPresenting = false

        XCTAssertEqual(received, .cancelled)
    }

    // MARK: - reducer 挂钩：dismiss action → cancelRoute（编程式消失）

    func testDismissActionTriggersCancelRoute() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData)))

        // present 成功：level 0 正在展示
        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)
        XCTAssertNil(received)

        // 通过 dismissTopView() 编程式消失，经过 reducerDismissAction → checkSeekingOn → didDisappearOnLevel → cancelRoute
        presentStore.send(action: .dismissTopView())

        XCTAssertEqual(received, .cancelled)
    }

    // MARK: - reducer 挂钩：Void ResultData

    func testPresentVoidSuccessThenFinish() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<Void>?
        let routeData = ResultableRouteData<Void, Void>(()) { result in
            received = result
        }
        presentStore.send(action: .present(VoidResultPickerView.defaultRoute.wrapper(routeData)))

        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isPresenting, true)

        routeData.finishRoute()
        if case .finished = received {} else {
            XCTFail("Expected .finished, got \(String(describing: received))")
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS)

    // MARK: - presentFullCover + finishRoute

    func testPresentFullCoverSuccessThenFinish() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData), isFullCover: true))

        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, true)

        routeData.finishRoute("fullcover-result")
        XCTAssertEqual(received, .finished("fullcover-result"))
    }

    // MARK: - presentFullCover 界面消失 → cancelRoute

    func testPresentFullCoverDismissTriggersCancelRoute() {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        nonisolated(unsafe) var received: ViewResult<String>?
        let routeData = ResultableRouteData<String, String>("init") { result in
            received = result
        }
        presentStore.send(action: .present(ResultPickerView.defaultRoute.wrapper(routeData), isFullCover: true))

        XCTAssertEqual(presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting, true)

        // 模拟用户消失界面
        presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting = false

        XCTAssertEqual(received, .cancelled)
    }

    #endif

    // MARK: - PresentManager async API: present(route, data) → finished

    func testAsyncPresentWithDataReturnsFinished() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.present(ResultPickerView.defaultRoute, "hello")
        }

        // 等 present action 处理完毕，level 1 的 viewMaker 持有 ResultableRouteData
        await Task.yield()
        await Task.yield()

        let maker = presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker
        XCTAssertNotNil(maker)
        let routeData = maker?.initData as? ResultableRouteData<String, String>
        XCTAssertNotNil(routeData)

        routeData?.finishRoute("world")
        let result = try await task.value
        XCTAssertEqual(result, "world")
    }

    // MARK: - PresentManager async API: present(route, data) → cancelled

    func testAsyncPresentWithDataThrowsCancelled() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.present(ResultPickerView.defaultRoute, "hello")
        }

        await Task.yield()
        await Task.yield()

        // 模拟用户滑动消失
        presentStore.storage.innerPresentStores[0].first?.isPresenting = false

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch {
            XCTAssertEqual(error as? ViewRouteError, .cancelled)
        }
    }

    // MARK: - PresentManager async API: present(route, data) → failed

    func testAsyncPresentUnregisteredRouteThrowsFailed() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let unregisteredRoute = ResultViewRoute<String, String>("UnregisteredRoute")

        do {
            _ = try await presentStore.present(unregisteredRoute, "hello")
            XCTFail("Expected failed")
        } catch {
            guard case .failed = error as? ViewRouteError else {
                XCTFail("Expected .failed, got \(error)")
                return
            }
        }
    }

    // MARK: - PresentManager async API: present(route) void 参数 → finished

    func testAsyncPresentVoidRouteReturnsFinished() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.present(VoidInitStringResultPickerView.defaultRoute)
        }

        await Task.yield()
        await Task.yield()

        let maker = presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker
        let routeData = maker?.initData as? ResultableRouteData<Void, String>
        XCTAssertNotNil(routeData)

        routeData?.finishRoute("void-result")
        let result = try await task.value
        XCTAssertEqual(result, "void-result")
    }

    // MARK: - PresentManager async API: present(route) void 参数 → cancelled

    func testAsyncPresentVoidRouteThrowsCancelled() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.present(VoidInitStringResultPickerView.defaultRoute)
        }

        await Task.yield()
        await Task.yield()

        presentStore.storage.innerPresentStores[0].first?.isPresenting = false

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch {
            XCTAssertEqual(error as? ViewRouteError, .cancelled)
        }
    }

    #if os(iOS) || os(tvOS) || os(watchOS)

    // MARK: - PresentManager async API: presentFullCover(route, data) → finished

    func testAsyncPresentFullCoverWithDataReturnsFinished() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.presentFullCover(ResultPickerView.defaultRoute, "hello")
        }

        await Task.yield()
        await Task.yield()

        let maker = presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker
        let routeData = maker?.initData as? ResultableRouteData<String, String>
        XCTAssertNotNil(routeData)

        routeData?.finishRoute("fullcover-result")
        let result = try await task.value
        XCTAssertEqual(result, "fullcover-result")
    }

    // MARK: - PresentManager async API: presentFullCover(route, data) → cancelled

    func testAsyncPresentFullCoverWithDataThrowsCancelled() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.presentFullCover(ResultPickerView.defaultRoute, "hello")
        }

        await Task.yield()
        await Task.yield()

        presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting = false

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch {
            XCTAssertEqual(error as? ViewRouteError, .cancelled)
        }
    }

    // MARK: - PresentManager async API: presentFullCover(route) void 参数 → finished

    func testAsyncPresentFullCoverVoidRouteReturnsFinished() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.presentFullCover(VoidInitStringResultPickerView.defaultRoute)
        }

        await Task.yield()
        await Task.yield()

        let maker = presentStore.storage.innerPresentStores[1].first?.viewMaker as? RegisteredPresentableViewMaker
        let routeData = maker?.initData as? ResultableRouteData<Void, String>
        XCTAssertNotNil(routeData)

        routeData?.finishRoute("fc-void-result")
        let result = try await task.value
        XCTAssertEqual(result, "fc-void-result")
    }

    // MARK: - PresentManager async API: presentFullCover(route) void 参数 → cancelled

    func testAsyncPresentFullCoverVoidRouteThrowsCancelled() async throws {
        let presentStore = Store<PresentState>.box(.init(), configs: [.make(.useBoxOnShared, true)])
        let fakeRoot = FakeRootView(store: presentStore)
        XCTAssertTrue(fakeRoot.store === presentStore)

        let task = Task<String, Error> {
            try await presentStore.presentFullCover(VoidInitStringResultPickerView.defaultRoute)
        }

        await Task.yield()
        await Task.yield()

        presentStore.storage.innerPresentStores[0].first?.isFullCoverPresenting = false

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch {
            XCTAssertEqual(error as? ViewRouteError, .cancelled)
        }
    }

    #endif
}

// MARK: - 测试用 ResultableView

private struct ResultPickerView: PresentableView, ResultableView {
    typealias InitParam = String
    typealias ResultData = String

    let routeData: ResultableRouteData<String, String>

    init(_ routeData: ResultableRouteData<String, ResultData>) {
        self.routeData = routeData
    }

    var content: some View {
        Text("Picker")
    }
}

private struct VoidResultPickerView: PresentableView, ResultableView {
    typealias InitParam = Void
    typealias ResultData = Void

    let routeData: ResultableRouteData<Void, Void>

    init(_ routeData: ResultableRouteData<Void, Void>) {
        self.routeData = routeData
    }

    var content: some View {
        Text("Void Picker")
    }
}

private struct VoidInitStringResultPickerView: PresentableView, ResultableView {
    typealias InitParam = Void
    typealias ResultData = String

    let routeData: ResultableRouteData<Void, String>

    init(_ routeData: ResultableRouteData<Void, ResultData>) {
        self.routeData = routeData
    }

    var content: some View {
        Text("Void Init Picker")
    }
}
