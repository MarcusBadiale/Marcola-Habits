// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MCShared",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCShared", targets: ["MCShared"]),
    ],
    targets: [
        .target(name: "MCShared"),
    ]
)
