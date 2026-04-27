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
import PowerAuth2
import WultraPowerAuthNetworking

/// Helper that manages PowerAuth activation and networking service creation
/// for integration tests.
///
/// Server-dependent tests require a valid `config.json` in the test bundle.
/// See `Config/README.md` for setup instructions and field descriptions.
class IntegrationProxy {

    static let pin = "1234"

    private(set) var powerAuth: PowerAuthSDK?
    private(set) var operationsService: WPNNetworkingService?
    private(set) var onboardingService: WPNNetworkingService?
    private var activationId: String?
    private var config: Config?

    // MARK: - Service factories

    /// Creates a `WPNNetworkingService` pointed at the given base URL.
    /// Uses a dummy PowerAuth instance (no activation needed for basic endpoints).
    static func createPlainService(baseUrl: String) -> WPNNetworkingService {
        log("Creating plain service for \(baseUrl)")
        let pa = PowerAuthSDK(configuration: .init(
            instanceId: "plain-\(UUID().uuidString)",
            baseEndpointUrl: "https://localhost/",
            configuration: "ARCB+/qxpmLCa04AyT2IPXHKED4Heu76QU+v2PtnzQbe0sYBAUEEU05t3byEUdh90CBiBvqgr4sWU7r1YTAtdpTh3EygAUL791k66wy+SZM1qELw6zdoOHNFk/s4neDDqKtIQ5E5jg=="
        ))!
        WPNLogger.verboseLevel = .debug
        return WPNNetworkingService(
            powerAuth: pa,
            config: .init(baseUrl: URL(string: baseUrl)!),
            serviceName: "plain-service"
        )
    }

    // MARK: - Configuration

    static func loadConfig() -> Config? {
        let bundle = Bundle(for: IntegrationProxy.self)
        let url = bundle.url(forResource: "config", withExtension: "json", subdirectory: "IntegrationTests/Config")
            ?? bundle.url(forResource: "config", withExtension: "json", subdirectory: "Config")
            ?? bundle.url(forResource: "config", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else {
            log("Config not found in test bundle")
            return nil
        }
        log("Config loaded from \(url.lastPathComponent)")
        return try? JSONDecoder().decode(Config.self, from: data)
    }

    // MARK: - Activation flow
    
    /// Create PowerAuth, Config and Services instances
    func createPowerAuthAndServices() async throws -> (PowerAuthSDK, Config) {
        guard let config = Self.loadConfig() else {
            throw IntegrationError.configNotFound
        }
        self.config = config

        WPNLogger.verboseLevel = .debug

        log("Creating PowerAuthSDK with baseEndpointUrl: \(config.enrollmentServerUrl)")
        guard let pa = PowerAuthSDK(configuration: .init(
            instanceId: "integration-test",
            baseEndpointUrl: config.enrollmentServerUrl,
            configuration: config.sdkConfig
        )) else {
            throw IntegrationError.powerAuthCreationFailed
        }
        pa.removeActivationLocal()
        self.powerAuth = pa
        
        operationsService = WPNNetworkingService(
            powerAuth: pa,
            config: .init(baseUrl: URL(string: config.operationsServerUrl)!),
            serviceName: "integration-test"
        )
        log("Operations service created for \(config.operationsServerUrl)")

        onboardingService = WPNNetworkingService(
            powerAuth: pa,
            config: .init(baseUrl: URL(string: config.enrollmentServerOnboardingUrl)!),
            serviceName: "integration-test-onboarding"
        )
        log("Onboarding service created for \(config.enrollmentServerOnboardingUrl)")
        
        return (pa, config)
    }

    /// Creates a PowerAuth activation against the cloud server and sets up
    /// `operationsService` and `onboardingService` for signed/token/e2ee requests.
    func prepareActivation() async throws {
        
        let (pa, config) = try await createPowerAuthAndServices()
        
        log("Creating server activation...")
        let activation = try await createServerActivation(config: config)
        self.activationId = activation.activationId
        log("Server activation created: \(activation.activationId)")

        let paActivation = try PowerAuthActivation(activationCode: activation.activationCode, name: "integration-test")

        log("Creating local activation...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pa.createActivation(paActivation) { _, error in
                if let error {
                    IntegrationProxy.log("Local activation failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    do {
                        try pa.persistActivation(withPassword: Self.pin)
                        IntegrationProxy.log("Activation persisted successfully")
                        continuation.resume()
                    } catch {
                        IntegrationProxy.log("Persist activation failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Removes the activation from the server and clears local data.
    func cleanup() async {
        log("Cleaning up activation")
        guard let powerAuth else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            powerAuth.removeActivation(with: .possessionWithPassword(password: .init(string: Self.pin))) { error in
                if error != nil {
                    // on error, at least remove the activation locally
                    powerAuth.removeActivationLocal()
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Helpers

    struct Config: Decodable {
        let cloudServerUrl: String
        let cloudServerLogin: String
        let cloudServerPassword: String
        let cloudApplicationId: String
        let enrollmentServerUrl: String
        let enrollmentServerOnboardingUrl: String
        let operationsServerUrl: String
        let sdkConfig: String
    }

    private struct ActivationData {
        let activationId: String
        let activationCode: String
    }

    private func createServerActivation(config: Config) async throws -> ActivationData {
        let url = URL(string: "\(config.cloudServerUrl)/v2/registrations")!
        let body: [String: Any] = [
            "appId": config.cloudApplicationId,
            "userId": "test-user-\(UUID().uuidString)",
            "commitPhase": "ON_KEY_EXCHANGE" // to omit commit phase
        ]

        log("POST \(url.absoluteString)")
        let responseData = try await makeCloudRequest(url: url, body: body, config: config)

        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let activationId = json["registrationId"] as? String,
              let activationCode = json["activationCode"] as? String else {
            log("Failed to parse activation response: \(String(data: responseData, encoding: .utf8) ?? "")")
            throw IntegrationError.activationFailed
        }

        return ActivationData(activationId: activationId, activationCode: activationCode)
    }

    private func makeCloudRequest(url: URL, body: [String: Any], config: Config) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let credentials = "\(config.cloudServerLogin):\(config.cloudServerPassword)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            log("No HTTP response from \(url.absoluteString)")
            throw IntegrationError.cloudServerError
        }

        log("Response \(httpResponse.statusCode) from \(url.absoluteString)")

        guard httpResponse.statusCode == 200 else {
            log("Response body: \(String(decoding: data, as: UTF8.self))")
            throw IntegrationError.cloudServerError
        }

        return data
    }

    private static func log(_ message: String) {
        print("[IntegrationProxy] \(message)")
    }

    private func log(_ message: String) {
        Self.log(message)
    }
}

enum IntegrationError: Error, CustomStringConvertible {
    case configNotFound
    case powerAuthCreationFailed
    case activationFailed
    case cloudServerError

    var description: String {
        switch self {
        case .configNotFound: return "Integration config.json not found in test bundle"
        case .powerAuthCreationFailed: return "Failed to create PowerAuthSDK instance"
        case .activationFailed: return "Failed to create or commit activation"
        case .cloudServerError: return "Cloud server request failed"
        }
    }
}
