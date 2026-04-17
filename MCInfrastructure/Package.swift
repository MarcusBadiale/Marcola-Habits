// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCInfrastructure",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCPersistence", targets: ["MCPersistence"]),
        .library(name: "MCSyncAPI", targets: ["MCSyncAPI"]),
        .library(name: "MCSync", targets: ["MCSync"]),
        .library(name: "MCNetworking", targets: ["MCNetworking"]),
    ],
    dependencies: [
        .package(path: "../MCDomain"),
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(
            name: "MCPersistence",
            dependencies: [
                .product(name: "MCDomain", package: "MCDomain"),
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
        .target(name: "MCSyncAPI"),
        .target(
            name: "MCSync",
            dependencies: ["MCSyncAPI"]
        ),
        .target(name: "MCNetworking"),
    ]
)
