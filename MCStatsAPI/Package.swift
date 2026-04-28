// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCStatsAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCStatsAPI", targets: ["MCStatsAPI"]),
    ],
    targets: [
        .target(name: "MCStatsAPI"),
    ]
)
