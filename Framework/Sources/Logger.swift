//
//  Created by Shin Yamamoto on 2018/10/09.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import Foundation
import os.log

var log = {
    return Logger()
}()

#if __FP_LOG
struct Logger {
    private let osLog: OSLog
    private let s = DispatchSemaphore(value: 1)

    private enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case fault = 4

        var name: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            case .fault: return "FAULT"
            }
        }
        var shortName: String {
            switch self {
            case .debug:
                return "D/"
            case .info:
                return "I/"
            case .warning:
                return "W/"
            case .error:
                return "E/"
            case .fault:
                return "F/"
            }
        }
        @available(iOS 10.0, *)
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .info
            case .error: return .error
            case .fault: return .fault
            }
        }

        static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    fileprivate init() {
        osLog = OSLog(subsystem: "com.scenee.FloatingPanel", category: "FloatingPanel")
    }

    private func log(_ level: Level, _ message: Any, _ arguments: [Any], function: String, line: UInt) {
        _ = s.wait(timeout: .now() + 0.033)
        defer { s.signal() }

        let extraMessage: String = arguments.map({ String(describing: $0) }).joined(separator: " ")
        let log = "\(level.shortName) \(message) \(extraMessage) (\(function):\(line))"

        os_log("%@", log: osLog, type: level.osLogType, log)
    }

    private func getPrettyFunction(_ function: String, _ file: String) -> String {
        if let filename = file.split(separator: "/").last {
            return filename + ":" + function
        } else {
            return file + ":" + function
        }
    }

    func debug(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.debug, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func info(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.info, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func warning(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.warning, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func error(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.error, log, arguments, function: getPrettyFunction(function, file), line: line)
    }

    func fault(_ log: Any, _ arguments: Any..., function: String = #function, file: String  = #file, line: UInt = #line) {
        self.log(.fault, log, arguments, function: getPrettyFunction(function, file), line: line)
    }
}
#else
struct Logger {
    func debug(_ log: Any, _ arguments: Any...) { }
    func info(_ log: Any, _ arguments: Any...) { }
    func warning(_ log: Any, _ arguments: Any...) { }
    func error(_ log: Any, _ arguments: Any...) { }
    func fault(_ log: Any, _ arguments: Any...) { }
}
#endif
