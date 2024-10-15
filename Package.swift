// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SwiftyHaru",
    products: [
        .library(name: "SwiftyHaru", targets: ["SwiftyHaru"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0")
    ],
    targets: [
        .target(name: "CLibPNG", cSettings: [.define("PNG_ARM_NEON_OPT", to: "0")]),
        .target(name: "CLibHaru", dependencies: ["CLibPNG"]),
        .target(name: "SwiftyHaru", dependencies: ["CLibHaru"]),
        .testTarget(name: "SwiftyHaruTests", dependencies: ["SwiftyHaru", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")])
    ]
)
