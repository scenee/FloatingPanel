// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import os.log

let msg = StaticString("%{public}@")
let sysLog = OSLog(subsystem: Logging.subsystem, category: Logging.category)
#if FP_LOG
let devLog = OSLog(subsystem: Logging.subsystem, category: "\(Logging.category):dev")
#else
let devLog = OSLog.disabled
#endif

struct Logging {
    static let subsystem = "com.scenee.FloatingPanel"
    static let category = "FloatingPanel"
    private init() {}
}
