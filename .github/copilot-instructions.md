# Copilot instructions for `networking-apple`

This repository builds **Wultra PowerAuth Networking**, a PowerAuth-focused HTTP client for Apple platforms. It is meant for apps that already have a configured `PowerAuthSDK` and want a typed transport layer for request signing, token-based authorization, optional end-to-end encryption, and shared response/error handling.

## Build, test, and lint

- `./scripts/swiftlint.sh` runs the repo's pinned SwiftLint (`0.53.0`). The script downloads or replaces the `./swiftlint` binary in the repo root as needed.
- `./scripts/build.sh` resolves Swift package dependencies for `WultraPowerAuthNetworking.xcodeproj`, then builds `WultraPowerAuthNetworking.xcodeproj` in `Release` for iOS, iOS Simulator, Mac Catalyst, tvOS, and tvOS Simulator.
- `./scripts/test.sh` resolves the best available iOS Simulator destination for `WultraPowerAuthNetworkingTests` via the shared `get-ios-sim.js` helper from the Wultra infrastructure repository, removes the repo-local `build/` directory, resolves Swift package dependencies for `WultraPowerAuthNetworking.xcodeproj`, and executes the `WultraPowerAuthNetworkingTests` scheme in `Debug`.
- Use the Xcode project and schemes for validation. CI builds and tests through `WultraPowerAuthNetworking.xcodeproj`, not `swift test`.
- Single-test example, following the same destination setup as `scripts/test.sh`:

```bash
SCRIPT_FOLDER="$(pwd)/scripts"
URL="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile/mobile/utils/ios-get-simulator/v1/get-ios-sim.js"
XCODE_PROJECT="WultraPowerAuthNetworking.xcodeproj"
XCODE_SCHEME="WultraPowerAuthNetworkingTests"
DESTINATION=$(curl -fsSL "${URL}" | node - -p "${SCRIPT_FOLDER}/.." "${XCODE_PROJECT}" "${XCODE_SCHEME}")

xcrun xcodebuild \
  -derivedDataPath build \
  -project "${XCODE_PROJECT}" \
  -scheme "${XCODE_SCHEME}" \
  -destination "${DESTINATION}" \
  -parallel-testing-enabled NO \
  -configuration Debug \
  -only-testing:WultraPowerAuthNetworkingTests/JSONTests/testDateDeserialization \
  test
```

- CI runs `sh ./scripts/xcodeselect.sh` before build and test. If local and CI behavior diverge, inspect that script and the selected Xcode version first.

## High-level architecture

- This SDK sits on top of PowerAuth rather than replacing it. App code still owns activation and `PowerAuthSDK` lifecycle; `WPNNetworkingService` consumes that configured instance to sign requests, generate token authorization headers, and obtain ECIES encryptors.
- `WPNNetworkingService` is the single orchestration point for request signing, optional end-to-end encryption, transport, response decoding, and error mapping.
- Endpoint behavior is encoded in types, not flags passed at call sites:
  - `WPNEndpointBasic` for unsigned endpoints
  - `WPNEndpointSigned` for PowerAuth-signed endpoints
  - `WPNEndpointSignedWithToken` for token-signed endpoints
- The transport flow spans several files:
  - `WPNNetworkingService.swift` creates typed requests, adds default headers, decides whether the operation goes through the shared serial PowerAuth queue or the service's concurrent queue, and obtains ECIES encryptors when `endpoint.e2ee` is enabled.
  - `WPNHttpRequest.swift` JSON-encodes requests, wraps encrypted payloads into the ECIES cryptogram envelope, and decodes or decrypts response envelopes.
  - `WPNHttpClient.swift` sends the `URLRequest` through an ephemeral `URLSession` and delegates TLS handling to `WPNSSLValidationStrategy`.
  - `WPNError.swift`, `WPNBaseNetworkingObjects.swift`, and `WPNResponseDelegate.swift` define how response envelopes, backend errors, raw traffic, and PowerAuth/network failures are surfaced.
- Signed requests are serialized by default through `PowerAuthSDK.executeOperation(onSerialQueue:)`. Unsigned requests use the service-owned `OperationQueue` unless `concurrencyStrategy` is explicitly changed to `.concurrentAll`.
- End-to-end encryption is configured per endpoint through `WPNE2EEConfiguration`; callers opt in on the endpoint definition and do not manually encrypt or decrypt payloads.

## Key conventions

- The library is intentionally POST-only. `WPNNetworkingService` exposes `post(...)` overloads, and `WPNHttpRequest.method` is fixed to `"POST"`.
- Request and response models use envelope base classes, not bare top-level payload types. Requests inherit from `WPNRequestBase`; responses inherit from `WPNResponseBase` or use the standard wrappers `WPNResponse<T>` / `WPNResponseArray<T>`. The backend contract expects `requestObject`, `responseObject`, and `status`.
- Success means a decoded envelope with `status == .Ok`. A 200 response with an unexpected body maps to `network_invalidResponseObject`; backend business errors are expected inside `responseObject` as `WPNRestApiError`.
- Preserve existing transport defaults unless the task is explicitly changing them:
  - `acceptLanguage` defaults to `"en"` and is not persisted across launches
  - `jsonDecoder` uses the repo's custom ISO-8601 date strategy to accept fractional seconds
  - `jsonEncoder` uses `.iso8601`
  - `WPNLogger.logHttpTraffic` is `true` by default
- `Package.swift` intentionally forces the target path to `Sources/WultraPowerauthNetworking` because the source folder's casing is historical. Do not "fix" that casing in one place only.
- The Xcode project resolves PowerAuth through `https://github.com/wultra/powerauth-mobile-sdk.git`. Only `PowerAuth2` is imported. Keep the Xcode project package products aligned with `Package.swift` instead of reintroducing Carthage framework links.
- Use spaces for indentation in repository-maintained scripts; do not introduce tab-indented shell lines.
- `scripts/test.sh` always recreates the `build/` directory, so do not store anything there that needs to survive test runs.
- The project ships through SPM and CocoaPods, and release prep verifies README metadata too. Version-related changes usually need matching updates in `WultraPowerAuthNetworking.podspec`, `Sources/WultraPowerauthNetworking/WPNConstants.swift`, and the README compatibility/changelog sections covered by `.prepare-release.json`.
- Tests live in the `WultraPowerAuthNetworkingTests` scheme and usually rely on `TestUtils.createFakeService()` with `@testable import WultraPowerAuthNetworking` rather than extra integration scaffolding.
- Place helper classes, mock/stub types, and private utility methods at the **end** of the file or enclosing class — after test methods and production logic, not before them. Use a `// MARK: - Helpers` separator.
