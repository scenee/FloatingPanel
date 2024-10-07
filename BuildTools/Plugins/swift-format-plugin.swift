import Foundation
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
        #if swift(>=6.0)
        let swift = try context.tool(named: "swift").url
        let xcodeProjectDirectoryURL = context.xcodeProject.directoryURL
        #else
        let swift = try context.tool(named: "swift").path
        let xcodeProjectDirectoryURL = URL(fileURLWithPath: context.xcodeProject.directory.string)
        #endif
        // Find the code generator tool to run (replace this with the actual one).
        print("SwiftFormatBuildToolPlugin -> \(xcodeProjectDirectoryURL.path())")
        let configFile = xcodeProjectDirectoryURL.appending(path: ".swift-format")
        // Currently check only 'SwiftUI' source code.
        let sourceFiles = xcodeProjectDirectoryURL.appending(path: "Sources/SwiftUI")
        // let sourceFiles = xcodeProjectDirectoryURL.appending(path: "Sources")
        // let testFiles = xcodeProjectDirectoryURL.appending(path: "Tests")
        let buildToolsFiles = xcodeProjectDirectoryURL.appending(path: "BuildTools")
        let examplesFiles = [
            xcodeProjectDirectoryURL.appending(path: "Examples/SamplesSwiftUI").path()
        ]
        return [
            .buildCommand(
                displayName: "Run swift format(xcode)",
                executable: swift,
                arguments: [
                    "format",
                    "lint",
                    "--configuration",
                    configFile.path(),
                    "-r",
                    sourceFiles.path(),
                    //testFiles.path(),
                    buildToolsFiles.path(),
                ] + examplesFiles,
                inputFiles: [],
                outputFiles: []
            )
        ]
    }
}
#endif
