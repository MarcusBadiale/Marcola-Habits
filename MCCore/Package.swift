// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCCore", targets: ["MCCore"]),
    ],
    dependencies: [
        .package(path: "../MCShared"),
    ],
    targets: [
        .target(
            name: "MCCore",
            dependencies: [
                .product(name: "MCShared", package: "MCShared"),
            ]
        ),
    ]
)
