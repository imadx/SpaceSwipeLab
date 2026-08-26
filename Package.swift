// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SpaceSwipeLab",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SpaceSwipeLab", targets: ["SpaceSwipeLab"])
    ],
    targets: [
        .executableTarget(
            name: "SpaceSwipeLab",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "SpaceSwipeLabTests",
            dependencies: ["SpaceSwipeLab"]
        )
    ]
)
