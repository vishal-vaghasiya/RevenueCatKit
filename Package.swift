// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RevenueCatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "RevenueCatKit",
            targets: ["RevenueCatKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/RevenueCat/purchases-ios-spm.git",
            from: "5.40.0"
        ),
    ],
    targets: [
        .target(
            name: "RevenueCatKit",
            dependencies: [.product(name: "RevenueCat", package: "purchases-ios-spm")],
            path: "Sources/RevenueCatKit"
        ),
    ]
)
