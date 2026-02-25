//
//  PresentMonitor.swift
//  
//
//  Created by 黄磊 on 2022/9/12.
//

import Foundation
import Combine
import ViewFlow
import ModuleMonitor

/// 对应路由未找到
public enum TargetRouteNotFound: Equatable, CustomStringConvertible, Sendable {
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

/// 展示器变化事件
public enum PresentEvent: MonitorEvent {
    case presentFailed(AnyViewRoute, TargetRouteNotFound)
    case presentFailedNotRegister(AnyViewRoute)
    case presentFailedCannotMakeInitData(AnyViewRoute)
    case presentFailedCannotMakeView(AnyViewRoute)
    case dismissFailed(TargetRouteNotFound)
    case freezeFailed(TargetRouteNotFound)
    case unfreezeFailed(TargetRouteNotFound)
    case fatalError(String)
}

/// 展示监听器观察者
public protocol PresentMonitorObserver: MonitorObserver {
    @MainActor
    func receivePresentEvent(_ event: PresentEvent)
}

/// 展示监听器
public final class PresentMonitor: ModuleMonitor<PresentEvent>, @unchecked Sendable {
    public static let shared: PresentMonitor = DispatchQueue.syncOnMonitorQueue {
        PresentMonitor { event, observer in
            DispatchQueue.executeOnMain {
                (observer as? PresentMonitorObserver)?.receivePresentEvent(event)
            }
        }
    }

    public func addObserver(_ observer: PresentMonitorObserver) -> AnyCancellable {
        super.addObserver(observer)
    }

    public override func addObserver(_ observer: MonitorObserver) -> AnyCancellable {
        Swift.fatalError("Only PresentMonitorObserver can observer this monitor")
    }
}
