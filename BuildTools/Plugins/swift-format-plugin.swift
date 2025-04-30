import Foundation
import PackagePlugin

@main
struct SwiftFormatBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // Currently the build tool plugin is not supported.
        return []
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

/// Formats Swift source files using the `swift format` command and a root configuration file during Xcode builds.
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
        print("SwiftFormatBuildToolPlugin -> \(xcodeProjectDirectoryURL.filePath)")
        let configFile = xcodeProjectDirectoryURL.appending(path: ".swift-format").filePath
        let targetFiles = [
            // Currently check only 'SwiftUI' source code in 'Sources' dir.
            xcodeProjectDirectoryURL.appending(path: "Sources/SwiftUI"),
            // xcodeProjectDirectoryURL.appending(path: "Sources"),
            // xcodeProjectDirectoryURL.appending(path: "Tests"),
            xcodeProjectDirectoryURL.appending(path: "BuildTools"),
            // Currently check only 'SamplesSwiftUI' source code in 'Examples' dir.
            xcodeProjectDirectoryURL.appending(path: "Examples/SamplesSwiftUI"),
        ].map { $0.filePath }
        return [
            .buildCommand(
                displayName: "Run swift format(xcode)",
                executable: swift,
                arguments: [
                    "format",
                    "lint",
                    "--configuration",
                    configFile,
                    "-r",
                ] + targetFiles,
                inputFiles: [],
                outputFiles: []
            )
        ]
    }
}

extension URL {
    /// Returns a non–percent-encoded path for use with components containing non-ASCII characters.
    var filePath: String { path(percentEncoded: false) }
}
#endif
