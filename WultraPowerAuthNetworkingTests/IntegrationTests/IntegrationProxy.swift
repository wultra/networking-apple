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

/// Helper that manages PowerAuth activation, cloud-server orchestration and
/// networking service creation for integration tests.
///
/// Server-dependent tests require a valid `config.json` in the test bundle.
/// See `Config/README.md` for setup instructions and field descriptions.
class IntegrationProxy {

    // MARK: - Public state

    let pin: String
    private(set) var powerAuth: PowerAuthSDK?
    private(set) var activationId: String?

    private let activationName = UUID().uuidString
    private let config: Config

    // MARK: - Inits

    /// Creates a proxy bound to the given `Config`. The PowerAuth instance is
    /// not created yet; call `initializePowerauth()` to fetch the SDK
    /// configuration from the cloud server and instantiate `powerAuth`.
    init(config: Config, pin: String = UUID().uuidString) {
        self.pin = pin
        self.config = config
    }

    // MARK: - PowerAuth setup

    /// Fetches the application detail from the PowerAuth Cloud admin API and
    /// uses its `mobileSdkConfig` to instantiate `powerAuth`. Any local
    /// activation is cleared. Does not activate the instance — call
    /// `prepareActivation()` afterwards if needed.
    func initializePowerauth() async throws {
        let detail = try await getApplicationDetail()
        guard let pa = PowerAuthSDK(configuration: .init(
            instanceId: "integration-test",
            baseEndpointUrl: config.enrollmentServerUrl,
            configuration: detail.mobileSdkConfig
        )) else {
            throw IntegrationError.powerAuthCreationFailed
        }
        pa.removeActivationLocal()
        self.powerAuth = pa
        log("PowerAuthSDK initialized with baseEndpointUrl: \(config.enrollmentServerUrl)")
    }

    /// Returns application detail from PowerAuth Cloud admin API
    /// (`GET /admin/applications/{id}`).
    func getApplicationDetail() async throws -> ApplicationDetail {
        return try await makeCloudRequest(
            path: "/admin/applications/\(config.cloudApplicationId)",
            method: "GET"
        )
    }

    // MARK: - Activation

    /// Creates a PowerAuth activation against the cloud server.
    /// Requires `initializePowerauth()` to have been called first.
    func prepareActivation() async throws {

        guard let pa = powerAuth else {
            throw IntegrationError.powerAuthNotInitialized
        }

        log("Creating server activation...")
        let activation = try await createServerActivation(config: config)
        self.activationId = activation.activationId
        log("Server activation created: \(activation.activationId)")

        let paActivation = try PowerAuthActivation(activationCode: activation.activationCode, name: UUID().uuidString)

        log("Creating local activation...")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pa.createActivation(paActivation) { [self] _, error in
                if let error {
                    log("Local activation failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    do {
                        try pa.persistActivation(withPassword: self.pin)
                        log("Activation persisted successfully")
                        continuation.resume()
                    } catch {
                        log("Persist activation failed: \(error.localizedDescription)")
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
            powerAuth.removeActivation(with: .possessionWithPassword(password: .init(string: pin))) { error in
                if error != nil {
                    // on error, at least remove the activation locally
                    powerAuth.removeActivationLocal()
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Operations

    enum Factors {
        case F_2FA
    }

    /// Creates a personalised operation on the cloud server for the proxy's user.
    func createOperation(_ factors: Factors = .F_2FA) async throws -> OperationObject {
        let body: String
        switch factors {
        case .F_2FA:
            body = """
            {
              "userId": "\(activationName)",
              "template": "login",
              "parameters": {
                "party.id": "666",
                "party.name": "Datová schránka",
                "session.id": "123",
                "session.ip-address": "192.168.0.1"
              }
            }
            """
        }
        return try await makeCloudRequest(path: "/v2/operations", jsonBody: body)
    }

    /// Cancels an operation on the cloud server with the given reason.
    func cancelOperation(operationId: String, reason: String) async throws -> CancelObject {
        return try await makeCloudRequest(
            path: "/v2/operations/\(operationId)?statusReason=\(reason)",
            method: "DELETE"
        )
    }

    /// Creates a non-personalised proximity-check operation on the cloud server.
    func createNonPersonalisedPACOperation(_ factors: Factors = .F_2FA) async throws -> OperationObject {
        let body: String
        switch factors {
        case .F_2FA:
            body = """
            {
              "template": "login_preApproval",
              "proximityCheckEnabled": true,
              "parameters": {
                "party.id": "666",
                "party.name": "Datová schránka",
                "session.id": "123",
                "session.ip-address": "192.168.0.1"
              }
            }
            """
        }
        return try await makeCloudRequest(path: "/v2/operations", jsonBody: body)
    }

    /// Fetches operation details by id.
    func getOperation(operationId: String) async throws -> OperationObject {
        return try await makeCloudRequest(path: "/v2/operations/\(operationId)", method: "GET")
    }

    /// Fetches QR-code (offline) data for an operation. Requires an activation.
    func getQROperation(operationId: String) async throws -> QROperationData {
        guard let activationId else { throw IntegrationError.activationRequired }
        return try await makeCloudRequest(
            path: "/v2/operations/\(operationId)/offline/qr?registrationId=\(activationId)",
            method: "GET"
        )
    }

    /// Verifies the OTP produced from a QR operation. Requires an activation.
    func verifyQROperation(operationId: String, operationData: QROperationData, otp: String) async throws -> QROperationVerify {
        guard let activationId else { throw IntegrationError.activationRequired }
        let body = """
        {
          "otp": "\(otp)",
          "nonce": "\(operationData.nonce)",
          "registrationId": "\(activationId)"
        }
        """
        return try await makeCloudRequest(path: "/v2/operations/\(operationId)/offline/otp", jsonBody: body)
    }

    // MARK: - Inbox

    /// Creates `count` inbox messages for the proxy's user. Returns details for
    /// successfully created messages (failures are logged and skipped).
    func createInboxMessages(
        count: Int,
        defaultType: String = "text",
        createFunc: ((Int) -> InboxMessage)? = nil
    ) async throws -> [InboxMessageDetail] {

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        var result: [InboxMessageDetail] = []
        for index in 1...count {
            let message = createFunc?(index) ?? InboxMessage(
                subject: "Message #\(index)",
                summary: "This is body for message \(index).",
                body: "This is body for message \(index).",
                type: defaultType
            )
            let body = """
            {
                "userId":"\(activationName)",
                "subject":"\(message.subject)",
                "summary":"\(message.summary)",
                "body":"\(message.body)",
                "type":"\(message.type)",
                "silent":true
            }
            """
            do {
                let detail: InboxMessageDetail = try await makeCloudRequest(
                    path: "/v2/inbox/messages",
                    jsonBody: body,
                    decoder: decoder
                )
                result.append(detail)
            } catch {
                log("ERROR: Failed to create message #\(index): \(error)")
            }
        }
        return result
    }

    // MARK: - OIDC

    /// Returns OIDC provider properties from the configuration, when present.
    func getOIDCProviders() -> OIDCProperties? {
        guard
            let providerId = config.oidcProviderId,
            let providerIdPkce = config.oidcProviderIdPkce
        else {
            return nil
        }
        return OIDCProperties(providerId: providerId, providerIdPkce: providerIdPkce)
    }

    // MARK: - Helpers

    private struct ActivationData {
        let activationId: String
        let activationCode: String
    }

    private func createServerActivation(config: Config) async throws -> ActivationData {
        let body = """
        {
          "appId": "\(config.cloudApplicationId)",
          "userId": "\(activationName)",
          "commitPhase": "ON_KEY_EXCHANGE"
        }
        """
        struct RegistrationResponse: Decodable {
            let registrationId: String
            let activationCode: String
        }
        let response: RegistrationResponse = try await makeCloudRequest(path: "/v2/registrations", jsonBody: body)
        return ActivationData(activationId: response.registrationId, activationCode: response.activationCode)
    }

    private func makeCloudRequest<T: Decodable>(
        path: String,
        method: String = "POST",
        jsonBody: String = "",
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {

        let url = URL(string: "\(config.cloudServerUrl)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !jsonBody.isEmpty {
            request.httpBody = jsonBody.data(using: .utf8)
        }

        let credentials = "\(config.cloudServerLogin):\(config.cloudServerPassword)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        log("\(method) \(url.absoluteString)")
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

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            log("Failed to decode response: \(String(decoding: data, as: UTF8.self))")
            throw error
        }
    }

    private func log(_ message: String) {
        print("[IntegrationProxy] \(message)")
    }
}

// MARK: - Errors

enum IntegrationError: Error, CustomStringConvertible {
    case powerAuthCreationFailed
    case powerAuthNotInitialized
    case activationFailed
    case activationRequired
    case cloudServerError

    var description: String {
        switch self {
        case .powerAuthCreationFailed: return "Failed to create PowerAuthSDK instance"
        case .powerAuthNotInitialized: return "PowerAuth has not been initialized; call initializePowerauth() first"
        case .activationFailed: return "Failed to create or commit activation"
        case .activationRequired: return "Operation requires an active activation; call prepareActivation() first"
        case .cloudServerError: return "Cloud server request failed"
        }
    }
}

// MARK: - Config

struct Config: Decodable {
    let cloudServerUrl: String
    let cloudServerLogin: String
    let cloudServerPassword: String
    let cloudApplicationId: String
    let enrollmentServerUrl: String
    let oidcProviderId: String?
    let oidcProviderIdPkce: String?
}

// MARK: - Cloud server models

struct ApplicationDetail: Decodable {
    let id: String
    let serviceBaseUrl: String
    let appKey: String
    let appSecret: String
    let mobileSdkConfig: String
}

struct OperationObject: Decodable {
    let operationId: String
    let userId: String?
    let status: String
    let operationType: String
    let failureCount: Int
    let maxFailureCount: Int
    let timestampCreated: Int
    let timestampExpires: Int
    let proximityOtp: String?
    /// Additional data is dictionary of [String: Any] but we use TestAdditionalData for tests to be able to decode it in non-generic way.
    /// If you need any more specific data, you can add it to TestAdditionalData.
    let additionalData: TestAdditionalData?
}

struct TestAdditionalData: Decodable {
    let mobileTokenData: TestMobileTokenData?
}

struct TestMobileTokenData: Decodable {
    let test1: Int?
    let test2: Double?
    let test3: String?
    let test4: [String: Bool]?

    let preApprovalScreens: [TestPreApprovalVisit]?
    let customRecord: CustomRecordData?
}

struct TestPreApprovalVisit: Decodable {
    let screen: String?
    let timestampOpened: String?
    let timestampClosed: String?
    let action: String?
}

struct CustomRecordData: Decodable {
    let flag: Bool?
    let mode: String?
}

struct CancelObject: Decodable {
    let status: String
}

struct QROperationData: Decodable {
    let operationQrCodeData: String
    let nonce: String
}

struct QROperationVerify: Decodable {
    let otpValid: Bool
    let userId: String
    let registrationId: String
    let registrationStatus: String
    let signatureType: String
    let remainingAttempts: Int
}

struct InboxMessage: Codable {
    let subject: String
    let summary: String
    let body: String
    let type: String
}

struct InboxMessageDetail: Decodable {
    let id: String
    let subject: String
    let summary: String
    let body: String
    let type: String
    let timestamp: Date
    let read: Bool
}

struct OIDCProperties {
    let providerId: String
    let providerIdPkce: String
}

// MARK: - Networking service factory

#if canImport(WultraPowerAuthNetworking)
import WultraPowerAuthNetworking

extension IntegrationProxy {

    /// Creates a `WPNNetworkingService` pointed at the given URL using this
    /// proxy's PowerAuth instance. Throws if `initializePowerauth()` has not
    /// been called yet.
    func createNetworkingService(url: String, serviceName: String = UUID().uuidString) throws -> WPNNetworkingService {
        guard let powerAuth else {
            throw IntegrationError.powerAuthNotInitialized
        }
        WPNLogger.verboseLevel = .debug
        return WPNNetworkingService(
            powerAuth: powerAuth,
            config: .init(baseUrl: URL(string: url)!),
            serviceName: serviceName
        )
    }
}
#endif
