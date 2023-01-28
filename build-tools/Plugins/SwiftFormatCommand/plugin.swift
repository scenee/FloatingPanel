import Foundation
import PackagePlugin

@main
struct SwiftFormatCommand: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        debugPrint("CommandPlugin start: \(context)")

        let swiftFormatTool = try context.tool(named: "swift-format")
        debugPrint("XcodeCommandPlugin: swift-format: \(swiftFormatTool.path)")

        let configFile = context.package.directory.appending(".swift-format")
        debugPrint("CommandPlugin using config: \(configFile)")

        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targetsToFormat = try context.package.targets(named: targetNames)

        let sourceCodeTargets = targetsToFormat.compactMap { $0 as? SourceModuleTarget }

        try runCommand(swiftFormatTool, configFile: configFile, filePaths: sourceCodeTargets.map(\.directory))
    }

    func runCommand(_ swiftFormatTool: PackagePlugin.PluginContext.Tool, configFile: Path, filePaths: [Path]) throws {
        // Invoke `swift-format` on the target directory, passing a configuration
        // file from the package directory.
        let swiftFormatExec = URL(fileURLWithPath: swiftFormatTool.path.string)
        let swiftFormatArgs =
            [
                "--configuration",
                "\(configFile.string)",
                "--in-place",
                "--recursive",
            ] + filePaths.map(\.string)
        let process = try Process.run(swiftFormatExec, arguments: swiftFormatArgs)
        process.waitUntilExit()

        debugPrint("result: \(process.terminationStatus)")

        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("success.")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("failed: \(problem)")
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
extension SwiftFormatCommand: XcodeCommandPlugin {
    func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
        debugPrint("start")

        let swiftFormatTool = try context.tool(named: "swift-format")
        debugPrint("swift-format executable = \(swiftFormatTool.path)")

        let configFile = context.xcodeProject.directory.appending(".swift-format")
        debugPrint("config file  = \(swiftFormatTool.path)")

        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let xcodeTargets = context.xcodeProject.targets.filter { targetNames.contains($0.product?.name ?? "") }

        let filePaths = xcodeTargets.flatMap(\.inputFiles).filter { $0.type == .source }.map(\.path)

        debugPrint("files to format = \(filePaths.map(\.lastComponent))")

        try runCommand(swiftFormatTool, configFile: configFile, filePaths: filePaths)
    }
}
#endif
