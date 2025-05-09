// swift-tools-version: 5.9
// This file is used when the 'built-tools' package is built by Xcode 15 or earlier.

import PackageDescription

let package = Package(
    name: "build-tools",
    products: [
        .plugin(
            name: "swift-format-plugin",
            targets: ["swift-format-plugin"]
        )
    ],
    targets: [
        .plugin(
            name: "swift-format-plugin",
            capability: .buildTool()
        )
    ]
)
