//
// Copyright 2022 Wultra s.r.o.
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

import UIKit
import Network

internal extension Bundle {
    var bundleVersion: Int? { Int(infoDictionary?[kCFBundleVersionKey as String] as? String ?? "") }
    var versionString: String? { infoDictionary?["CFBundleShortVersionString"] as? String }
    var identifier: String? { infoDictionary?[kCFBundleIdentifierKey as String] as? String }
    var executable: String? { infoDictionary?[kCFBundleExecutableKey as String] as? String }
}

internal extension UIDevice {
    
    static let deviceModel: String = {

        var sysinfo = utsname()
        uname(&sysinfo)
        
        guard let sysname = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters).lowercased() else {
            return "UNKNOWN"
        }
        
        if sysname == "i386" || sysname == "x86_64" {
            return "SIMULATOR"
        }
        
        return sysname
    }()
}

internal class WPNConnectionMonitor {
    
    enum Status: String {
        case unknown
        case noConnection
        case wifi
        case cellular
        case wired
        case loopback
    }
    
    var status: Status {
        guard #available(iOS 12.0, *), let monitor = self.monitor as? NWPathMonitor else {
            // fallback for iOS11 and older. There is no direct way how to easily get the network status without
            // some utility class. As this is just a metadata info, we'll do it the best effort way.
            return .unknown
        }
        let path = monitor.currentPath
        
        if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .unknown
        }
    }
    
    private let monitor: Any?
    
    init() {
        if #available(iOS 12.0, *) {
            let m = NWPathMonitor()
            m.start(queue: .global())
            monitor = m
        } else {
            monitor = nil
        }
    }
    
    deinit {
        if #available(iOS 12.0, *) {
            if let monitor = self.monitor as? NWPathMonitor {
                monitor.cancel()
            }
        }
    }
}
