//
// Copyright 2020 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import Foundation

/// Level of the log
public enum WPNLogLevel {
    /// Debug logs. Might contain sensitive data like body of the request etc.
    /// You should only use this level during development.
    case debug
    /// Regular library logic logs
    case info
    /// Non-critical warning
    case warning
    /// Error happened
    case error
    
    fileprivate var minVerboseLevel: WPNLogger.VerboseLevel {
        return switch self {
        case .debug: .debug
        case .info: .info
        case .warning: .warnings
        case .error: .errors
        }
    }
    
    fileprivate var logName: String {
        return switch self {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        }
    }
}

/// Delegate that can further process logs from the library
public protocol WPNLoggerDelegate: AnyObject {
    
    /// If the delegate should follow selected verbosity level.
    ///
    /// When set to true, then (for example) if `errors` is selected as a `verboseLevel`, only `error` logLevel will be called.
    /// When set to false, all methods might be called no matter the selected `verboseLevel`.
    var wpnFollowVerboseLevel: Bool { get }
    
    /// Log was recorded
    /// - Parameters:
    ///   - message: Message of the log
    ///   - logLevel: Log level
    func wpnLog(message: String, logLevel: WPNLogLevel)
}

/// WPNLogger provides simple logging facility.
public class WPNLogger {
    
    /// Verbose level of the logger.
    public enum VerboseLevel: Int {
        /// Silences all messages.
        case off = 0
        /// Only errors will be printed to the system console.
        case errors = 1
        /// Errors and warnings will be printed to the system console.
        case warnings = 2
        /// Error ,warning and info messages will be printed to the system console.
        case info = 3
        /// All messages will be printed to the system console - including debug messages
        case debug = 4
    }
    
    /// Logger delegate
    public static weak var delegate: WPNLoggerDelegate?
    
    /// Current verbose level. `warnings` by default
    public static var verboseLevel: VerboseLevel = .warnings
    
    /// If HTTP traffic should be reported by this logger. `true` by default
    ///
    /// You can use this option to stop log from the HTTP traffic when you setup your own logging logic
    /// via the `responseDelegate` and `requestDelegate` in the `WPNNetworkingService`.
    public static var logHttpTraffic = true
    
    /// Headers that won't be logged.
    ///
    /// Default headers to skip are:
    /// ```
    /// "accept-language", "content-type", "content-length", 
    /// "accept-language", "transfer-encoding", "date",
    /// "server", "user-agent", "connection", "x-content-type-options",
    /// "x-xss-protection", "cache-control", "pragma", "expires",
    /// "x-frame-options", "vary"
    /// ```
    public static let httpHeadersToSkip = HeaderBlockList()
    
    /// Character limit for single log message. Default is `12 000`. Unlimited when nil
    public static var characterLimit: Int? = 12_000
    
    /// Prints simple message to the system console.
    static func debug(_ message: @autoclosure () -> String) {
        log(message(), level: .debug)
    }
    
    /// Prints simple message to the system console.
    static func info(_ message: @autoclosure () -> String) {
        log(message(), level: .info)
    }

    /// Prints warning message to the system console.
    static func warning(_ message: @autoclosure () -> String) {
        log(message(), level: .warning)
    }
    
    /// Prints error message to the system console.
    static func error(_ message: @autoclosure () -> String) {
        log(message(), level: .error)
    }
    
    private static func log(_ message: @autoclosure () -> String, level: WPNLogLevel) {
        let levelAllowed = level.minVerboseLevel.rawValue <= verboseLevel.rawValue
        let forceReport = delegate?.wpnFollowVerboseLevel == false
        guard levelAllowed || forceReport else {
            // not logging
            return
        }
        
        let msg = message().limit(characterLimit)
        
        if levelAllowed {
            print("[WPN:\(level.logName)] \(msg)")
        }
        if levelAllowed || forceReport {
            delegate?.wpnLog(message: msg, logLevel: level)
        }
    }
    
    #if DEBUG
    /// Unconditionally prints a given message and stops execution
    ///
    /// - Parameters:
    ///   - message: The string to print. The default is an empty string.
    ///   - file: The file name to print with message. The default is file path where fatalError is called for DEBUG configuration, empty string for other
    ///   - line: The line number to print along with message. The default is the line number where fatalError is called.
    static func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
        Swift.fatalError(message(), file: file, line: line)
    }
    #else
    /// Unconditionally prints a given message and stops execution
    ///
    /// - Parameters:
    ///   - message: The string to print. The default is an empty string.
    ///   - file: The file name to print with message. The default is file path where fatalError is called for DEBUG configuration, empty string for other
    ///   - line: The line number to print along with message. The default is the line number where fatalError is called.
    static func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = "", line: UInt = #line) -> Never {
        Swift.fatalError(message(), file: file, line: line)
    }
    #endif
}

/// Headers to skip when logging.
///
/// Note that all headers are transformed to lowercase variant when added.
///
/// Default headers to skip are:
/// ```
/// "accept-language", "content-type", "content-length", "accept-language", "transfer-encoding", "date", "server", "user-agent",
/// "connection", "x-content-type-options", "x-xss-protection", "cache-control", "pragma", "expires", "x-frame-options", "vary"
/// ```
///
public class HeaderBlockList {

    private var headersToSkp = [
        "accept-language", "content-type", "content-length", "accept-language", "transfer-encoding", "date", "server", "user-agent",
        "connection", "x-content-type-options", "x-xss-protection", "cache-control", "pragma", "expires", "x-frame-options", "vary"
    ]
    
    /// Adds element to the block list.
    /// - Parameter element: HTTP header key to block.
    public func add(element: String) {
        headersToSkp.append(element.lowercased())
    }

    /// Adds elements to the block list.
    /// - Parameter element: HTTP header keys to block.
    public func add(elements: [String]) {
        headersToSkp.append(contentsOf: elements.map { $0.lowercased() })
    }

    /// Removes element from the block list.
    /// - Parameter element: HTTP header key to remove.
    public func remove(element: String) {
        headersToSkp.removeAll { $0 == element.lowercased() }
    }

    /// Removes elements from the block list.
    /// - Parameter element: HTTP header keys to remove.
    public func removeAll(elements: [String]) {
        elements.map { $0.lowercased() }.forEach {
            if let idx = headersToSkp.firstIndex(of: $0) {
                headersToSkp.remove(at: idx)
            }
        }
    }
    
    /// Remove all
    public func removeAll() {
        headersToSkp.removeAll()
    }
    
    /// Returns array of headers to skip
    /// - Returns: Headers to skip
    public func headersToSkip() -> [String] {
        return Array(headersToSkp)
    }
    
    func filterHeaders(headers: [String: String]?) -> String {
        
        guard let headers else {
            return "no headers"
        }
        
        var result = ""
        var skipped = 0
        
        for header in headers {
            if headersToSkp.contains(where: { $0 == header.key.lowercased() }) {
                skipped += 1
            } else {
                result += "\n  - \(header.key): \(header.value)"
            }
        }
        return "\(skipped) filtered out" + result
    }
}

private extension String {
    func limit(_ characterLimit: Int?) -> String {
        guard let cl = characterLimit else {
            return self
        }
        return String(prefix(cl))
    }
}

internal typealias D = WPNLogger
