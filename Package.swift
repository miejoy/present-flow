// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "present-flow",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PresentFlow",
            targets: ["PresentFlow"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/miejoy/view-flow.git", branch: "main"),
        .package(url: "https://github.com/miejoy/module-monitor.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PresentFlow",
            dependencies: [
                .product(name: "ViewFlow", package: "view-flow"),
                .product(name: "ModuleMonitor", package: "module-monitor")
            ]),
        .testTarget(
            name: "PresentFlowTests",
            dependencies: [
                "PresentFlow",
                .product(name: "XCTViewFlow", package: "view-flow")
            ]),
    ]
)
