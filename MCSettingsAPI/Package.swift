// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCSettingsAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MCSettingsAPI", targets: ["MCSettingsAPI"]),
    ],
    targets: [
        .target(name: "MCSettingsAPI"),
    ]
)
