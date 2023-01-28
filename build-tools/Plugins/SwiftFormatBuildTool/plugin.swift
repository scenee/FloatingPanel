import Foundation
import PackagePlugin

@main
struct SwiftFormatBuildTool: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        debugPrint("BuildToolPlugin -> \(context.package.directory)")
        let configFile = context.package.directory.appending(".swift-format")
        return [
            .prebuildCommand(
                displayName: "Run swift-format",
                executable: try context.tool(named: "swift-format").path,
                arguments: [
                    "lint",
                    "--configuration",
                    configFile.string,
                    "-r",
                    "\(context.pluginWorkDirectory.string)",
                ],
                outputFilesDirectory: context.package.directory
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
extension SwiftFormatBuildTool: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        debugPrint("XcodeBuildToolPlugin -> \(context.xcodeProject.directory.string)")
        let configFile = context.xcodeProject.directory.appending(".swift-format")
        let sourceFiles = context.xcodeProject.directory.appending("Sources")
        let testFiles = context.xcodeProject.directory.appending("Tests")
        return [
            .buildCommand(
                displayName: "Run swift-format(xcode)",
                executable: try context.tool(named: "swift-format").path,
                arguments: [
                    "lint",
                    "--configuration",
                    configFile.string,
                    "-r",
                    "\(sourceFiles.string)",
                    "\(testFiles.string)",
                ],
                inputFiles: [],
                outputFiles: []
            )
        ]
    }
}
#endif
