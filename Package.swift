// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultiArray",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MultiArray",
            targets: ["MultiArray"]),
    ],
    dependencies: [
        .package(url: "https://www.github.com/Vaida12345/Essentials", from: "1.0.43"),
        .package(url: "https://www.github.com/Vaida12345/FinderItem", from: "1.0.14"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "MultiArray", dependencies: ["Essentials", "FinderItem"], path: "MultiArray"),
        .testTarget(name: "MultiArrayTests", dependencies: ["MultiArray"], path: "Tests"),
        .executableTarget(name: "Client", dependencies: ["MultiArray"], path: "Client")
    ]
)
