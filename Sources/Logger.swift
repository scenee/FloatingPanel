// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import Foundation
import os.log

// Must be a variable to use `hook` property in testing
var log = {
    return Logger()
}()

struct Logger {
    private let osLog: OSLog
    private let s = DispatchSemaphore(value: 1)

    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        var displayName: String {
            switch self {
            case .debug:
                return "Debug:"
            case .info:
                return "Info:"
            case .warning:
                return "Warning:"
            case .error:
                return "Error:"
            }
        }
        @available(iOS 10.0, *)
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }

        static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    typealias Hook = ((String, Level) -> Void)
    var hook: Hook?

    fileprivate init() {
        osLog = OSLog(subsystem: "com.scenee.FloatingPanel", category: "FloatingPanel")
    }

    private func log(_ level: Level, _ message: Any, _ arguments: [Any], tag: String, function: String, line: UInt) {
        _ = s.wait(timeout: .now() + 0.033)
        defer { s.signal() }

        let extraMessage: String = arguments.map({ String(describing: $0) }).joined(separator: " ")
        let _tag = tag.isEmpty ? "" : "\(tag):"
        let log: String = {
            switch level {
            case .debug:
                return "\(level.displayName)\(_tag) \(message) \(extraMessage) (\(function):\(line))"
            default:
                return "\(level.displayName)\(_tag) \(message) \(extraMessage)"
            }
        }()

        hook?(log, level)

        os_log("%{public}@", log: osLog, type: level.osLogType, log)
    }

    private func getPrettyFunction(_ function: String, _ file: String) -> String {
        if let filename = file.split(separator: "/").last {
            return filename + ":" + function
        } else {
            return file + ":" + function
        }
    }

    func debug(_ log: Any, _ arguments: Any..., tag: String = "", function: String = #function, file: String  = #file, line: UInt = #line) {
        #if __FP_LOG
        self.log(.debug, log, arguments, tag: tag, function: getPrettyFunction(function, file), line: line)
        #endif
    }

    func info(_ log: Any, _ arguments: Any..., tag: String = "",  function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.info, log, arguments, tag: tag, function: getPrettyFunction(function, file), line: line)
    }

    func warning(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.warning, log, arguments, tag: "", function: getPrettyFunction(function, file), line: line)
    }

    func error(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.error, log, arguments, tag: "", function: getPrettyFunction(function, file), line: line)
    }
}
