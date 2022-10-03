//
//  PresentRoute.swift
//  
//
//  Created by 黄磊 on 2022/9/10.
//

import Foundation

/// 默认展示界面路由 ID
public let s_defaultPresentRouteId = "__default__"

/// 可展示界面对应路由标识
public struct PresentRoute<InitData>: Hashable, CustomStringConvertible {
    var routeId: String
    
    public init(routeId: String = s_defaultPresentRouteId) {
        self.routeId = routeId
    }
    
    public var description: String {
        "\(routeId)<\(String(describing: InitData.self).replacingOccurrences(of: "()", with: "Void"))>"
    }
}

public struct AnyPresentRoute: Equatable {
    
    var initDataType: Any.Type
    
    var routeId: String
    
    var hashValue: AnyHashable
    
    init<InitData>(route: PresentRoute<InitData>) {
        self.initDataType = InitData.self
        self.routeId = route.routeId
        self.hashValue = AnyHashable(route)
    }
    
    func equelToRoute<InitData>(_ route: PresentRoute<InitData>) -> Bool {
        InitData.self == initDataType && routeId == route.routeId
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public var description: String {
        "\(routeId)<\(String(describing: initDataType).replacingOccurrences(of: "()", with: "Void"))>"
    }
}

extension PresentRoute {
    public func eraseToAnyRoute() -> AnyPresentRoute {
        .init(route: self)
    }
}
