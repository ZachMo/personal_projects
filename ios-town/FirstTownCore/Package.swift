// swift-tools-version: 6.0
import PackageDescription

/// The rules of First Town with no UI: the map, the deck, placement, scoring and trophies.
/// It builds for macOS too, so `swift test` runs in seconds without a simulator.
let package = Package(
    name: "FirstTownCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FirstTownCore", targets: ["FirstTownCore"]),
    ],
    targets: [
        .target(name: "FirstTownCore"),
        .testTarget(name: "FirstTownCoreTests", dependencies: ["FirstTownCore"]),
    ]
)
