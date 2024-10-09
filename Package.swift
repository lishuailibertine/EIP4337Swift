// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EIP4337Swift",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EIP4337Swift",
            targets: ["EIP4337Swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/lishuailibertine/web3swift", exact: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EIP4337Swift",
            dependencies: [
                "web3swift"
            ]),
        .testTarget(
            name: "EIP4337SwiftTests",
            dependencies: ["EIP4337Swift"]),
    ]
)
