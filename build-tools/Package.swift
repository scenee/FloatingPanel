// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "build-tools",
    platforms: [.macOS(.v12)],
    products: [
        .plugin(name: "SwiftFormatCommand", targets: ["SwiftFormatCommand"]),
        .plugin(name: "SwiftFormatBuildTool", targets: ["SwiftFormatBuildTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-format.git", branch: "508.0.1")
    ],
    targets: [
        .plugin(
            name: "SwiftFormatCommand",
            capability: .command(
                intent: .sourceCodeFormatting(),
                permissions: [
                    .writeToPackageDirectory(reason: "")
                ]
            ),
            dependencies: [
                .product(name: "swift-format", package: "swift-format")
            ]
        ),
        .plugin(
            name: "SwiftFormatBuildTool",
            capability: .buildTool(),
            dependencies: [
                .product(name: "swift-format", package: "swift-format")
            ]
        ),
    ]
)
