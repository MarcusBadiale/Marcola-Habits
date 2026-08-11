// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MCShared",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCShared", targets: ["MCShared"]),
        .library(name: "MCMacros", targets: ["MCMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(name: "MCShared"),
        .macro(
            name: "MCMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "MCMacros",
            dependencies: ["MCMacrosPlugin"]
        ),
        .testTarget(
            name: "MCSharedTests",
            dependencies: ["MCShared"]
        ),
        .testTarget(
            name: "MCMacrosTests",
            dependencies: [
                "MCMacrosPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
