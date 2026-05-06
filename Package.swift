// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LifeTrackerMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LifeTrackerMac", targets: ["LifeTrackerMac"])
    ],
    targets: [
        .executableTarget(
            name: "LifeTrackerMac",
            path: "Sources/LifeTrackerMac",
            resources: [
                .copy("Resources/iconLife.png"),
                .copy("Resources/searchIcon.png")
            ]
        )
    ]
)
