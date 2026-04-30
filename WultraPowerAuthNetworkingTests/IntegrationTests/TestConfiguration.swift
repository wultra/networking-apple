//
// Copyright 2026 Wultra s.r.o.
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

/// Loads integration test configuration from `config.json` bundled with the
/// test target. See `Config/README.md` for setup instructions and field
/// descriptions.
class TestConfiguration {

    /// Full configuration as loaded from `config.json`. Includes test-only
    /// URLs that are not part of `IntegrationProxy.Config`.
    struct LoadedConfig: Decodable {
        let cloudServerUrl: String
        let cloudServerLogin: String
        let cloudServerPassword: String
        let cloudApplicationId: String
        let enrollmentServerUrl: String
        let enrollmentServerOnboardingUrl: String
        let operationsServerUrl: String
        let oidcProviderId: String?
        let oidcProviderIdPkce: String?

        /// Subset of fields suitable for `IntegrationProxy(config:)`.
        var config: Config {
            Config(
                cloudServerUrl: cloudServerUrl,
                cloudServerLogin: cloudServerLogin,
                cloudServerPassword: cloudServerPassword,
                cloudApplicationId: cloudApplicationId,
                enrollmentServerUrl: enrollmentServerUrl,
                oidcProviderId: oidcProviderId,
                oidcProviderIdPkce: oidcProviderIdPkce
            )
        }
    }

    /// Loads the integration `LoadedConfig` from the test bundle.
    /// Returns `nil` if no `config.json` is present.
    static func load() -> LoadedConfig? {
        let bundle = Bundle(for: TestConfiguration.self)
        let url = bundle.url(forResource: "config", withExtension: "json", subdirectory: "IntegrationTests/Config")
            ?? bundle.url(forResource: "config", withExtension: "json", subdirectory: "Config")
            ?? bundle.url(forResource: "config", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else {
            print("[TestConfiguration] Config not found in test bundle")
            return nil
        }
        print("[TestConfiguration] Config loaded from \(url.lastPathComponent)")
        return try? JSONDecoder().decode(LoadedConfig.self, from: data)
    }
}
