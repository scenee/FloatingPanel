import PackagePlugin

@main
struct SwiftFormatBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return []
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftFormatBuildToolPlugin: XcodeBuildToolPlugin {
    // Entry point for creating build commands for targets in Xcode projects.
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        // Find the code generator tool to run (replace this with the actual one).
        print("SwiftFormatBuildToolPlugin -> \(context.xcodeProject.directoryURL.path())")
        let configFile = context.xcodeProject.directoryURL.appending(path: ".swift-format")
        // Currently check only 'SwiftUI' source code.
        let sourceFiles = context.xcodeProject.directoryURL.appending(path: "Sources/SwiftUI")
        // let sourceFiles = context.xcodeProject.directoryURL.appending(path: "Sources")
        // let testFiles = context.xcodeProject.directoryURL.appending(path: "Tests")
        let buildToolsFiles = context.xcodeProject.directoryURL.appending(path: "BuildTools")
        return [
            .buildCommand(
                displayName: "Run swift format(xcode)",
                executable: try context.tool(named: "swift").url,
                arguments: [
                    "format",
                    "lint",
                    "--configuration",
                    configFile.path(),
                    "-r",
                    sourceFiles.path(),
                    //testFiles.path(),
                    buildToolsFiles.path(),
                ],
                inputFiles: [],
                outputFiles: []
            )
        ]
    }
}

#endif
