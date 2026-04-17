// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCDomain",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCDomain", targets: ["MCDomain"]),
    ],
    dependencies: [
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(
            name: "MCDomain",
            dependencies: [
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
    ]
)
