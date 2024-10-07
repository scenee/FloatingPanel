// swift-tools-version: 5.9

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
