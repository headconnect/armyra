// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Armyra",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ArmyraCore",
            targets: ["ArmyraCore"]
        ),
    ],
    targets: [
        .target(
            name: "ArmyraCore"
        ),
        .testTarget(
            name: "ArmyraCoreTests",
            dependencies: ["ArmyraCore"]
        ),
    ]
)