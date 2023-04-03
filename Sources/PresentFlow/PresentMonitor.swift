//
//  PresentMonitor.swift
//  
//
//  Created by 黄磊 on 2022/9/12.
//

import Foundation
import Combine
import ViewFlow

public enum TargetRouteNotFound: Equatable, CustomStringConvertible {
    case route(AnyViewRoute)
    case level(UInt)
    
    public var description: String {
        switch self {
        case .route(let anyPresentRoute):
            return "route of \(anyPresentRoute.description) not found"
        case .level(let level):
            return "route on \(level) not found"
        }
    }
}

/// 存储器变化事件
public enum PresentEvent {
    case presentFailed(AnyViewRoute, TargetRouteNotFound)
    case presentFailedNotRegister(AnyViewRoute)
    case dismissFailed(TargetRouteNotFound)
    case freezeFailed(TargetRouteNotFound)
    case unfreezeFailed(TargetRouteNotFound)
    case fatalError(String)
}

public protocol PresentMonitorOberver: AnyObject {
    func receivePresentEvent(_ event: PresentEvent)
}

/// 存储器监听器
public final class PresentMonitor {
        
    struct Observer {
        let observerId: Int
        weak var observer: PresentMonitorOberver?
    }
    
    /// 监听器共享单例
    public static var shared: PresentMonitor = .init()
    
    /// 所有观察者
    var arrObservers: [Observer] = []
    var generateObserverId: Int = 0
    
    required init() {
    }
    
    /// 添加观察者
    public func addObserver(_ observer: PresentMonitorOberver) -> AnyCancellable {
        generateObserverId += 1
        let observerId = generateObserverId
        arrObservers.append(.init(observerId: generateObserverId, observer: observer))
        return AnyCancellable { [weak self] in
            if let index = self?.arrObservers.firstIndex(where: { $0.observerId == observerId}) {
                self?.arrObservers.remove(at: index)
            }
        }
    }
    
    /// 记录对应事件，这里只负责将所有事件传递给观察者
    @usableFromInline
    func record(event: PresentEvent) {
        guard !arrObservers.isEmpty else { return }
        arrObservers.forEach { $0.observer?.receivePresentEvent(event) }
    }
    
    @usableFromInline
    func fatalError(_ message: String) {
        guard !arrObservers.isEmpty else {
            #if DEBUG
            Swift.fatalError(message)
            #else
            return
            #endif
        }
        arrObservers.forEach { $0.observer?.receivePresentEvent(.fatalError(message)) }
    }
}
