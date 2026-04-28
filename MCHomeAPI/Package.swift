// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCHomeAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCHomeAPI", targets: ["MCHomeAPI"]),
    ],
    targets: [
        .target(name: "MCHomeAPI"),
    ]
)
