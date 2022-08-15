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

/// Configuration of the User-Agent header.
public enum WPNUserAgent {
    /// System provided header
    case systemDefault
    /// Library provided header.
    ///
    /// The value can look like: `PowerAuthNetworking/1.2.0 (en;wifi) com.yourcompany.yourappid/1.0.0 (Apple; iOS/16.0; iPhone12,3)`
    case libraryDefault
    /// Custom user header.
    case custom(_ value: String)
    
    func getValue() -> String? {
        switch self {
        case .systemDefault:
            return nil
        case .custom(let value):
            return value
        case .libraryDefault:
            let connectionMonitor = WPNConnectionMonitor()
            let product = "PowerAuthNetworking"
            let sdkVer  = WPNConstants.sdkVersionName
            let appVer  = Bundle.main.versionString ?? ""
            let appId   = Bundle.main.identifier ?? "??"
            let lang    = Locale.preferredLanguages.first ?? "??"
            let maker   = "Apple" // i'll eat my shoes if this changes
            let os      = UIDevice.current.systemName
            let osVer   = UIDevice.current.systemVersion
            let model   = UIDevice.deviceModel
            let ntwrk   = connectionMonitor.status.rawValue
            
            return "\(product)/\(sdkVer) (\(lang); \(ntwrk)) \(appId)/\(appVer) (\(maker); \(os)/\(osVer); \(model))"
        }
    }
}
