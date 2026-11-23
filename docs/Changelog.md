# Changelog

## TBA

- Split the SDK documentation into topic guides under `docs/`.
- **Breaking:** Requires PowerAuth SDK `2.1.x` (`2.1.0` up to, but excluding, `2.2.0`).
- **Breaking:** Raised the minimum supported platform versions to iOS 15.0 and tvOS 15.0 (required by PowerAuth SDK 2.1.x).
- PowerAuth time is now synchronized before obtaining an ECIES encryptor for an encrypted (E2EE) endpoint, but only when the time is not already synchronized.

## 2.1.0

- Added `WPNConfig.requestInterceptors` for modifying the final request right before it is sent via `URLSession`. See the [Request Interceptors](Networking-Configuration.md#request-interceptors) docs section.

## 2.0.0
- Requires PowerAuth SDK `2.0.0`.
- PowerAuth time is now synchronized before requesting a token-based authorization header, but only when the token is not already cached locally.
- Raised the minimum supported platform versions to iOS 13.0 and tvOS 13.0.
- Added `async/await` counterparts to all public `WPNNetworkingService.post(...)` overloads.
- Added `network_e2eeError` and `network_tokenError` error reasons for more granular error handling.
- Renamed `WPNEndpointSigned` to `WPNEndpointAuthenticated` and `WPNEndpointSignedWithToken` to `WPNEndpointAuthenticatedWithToken` to align with updated PowerAuth terminology (authentication code instead of signature).
- Renamed `WPNRequestConcurrencyStrategy.serialSigned` to `.serialAuthenticated`.
- Renamed the `signedWith` parameter label in `post(...)` methods to `authenticatedWith`.

## 1.5.2
- Time is now always synchronized when creating token-based authorization headers

## 1.5.1
- Added `jsonDecoder` and `jsonEncoder` properties to the `WPNNetworkingService` for custom JSON formatting
- Better `iso8601` date deserialization by default
- Improved async operation state handling + better cancel handling
- Making `WPNRequest` `Encodable` instead of `Codable`

## 1.5.0
- Upgraded PowerAuthSDK to `1.9.x`  _(requires server 1.9+)_
- End-to-end encryption was moved from post functions to the endpoint definition

## 1.4.0
- Log improvements
- Removed the `serialAll` option from concurrency settings

## 1.3.2
- Added new `WPNKnownRestApiError` cases

## 1.3.0
- Upgraded PowerAuthSDK to `1.8.x` _(requires server 1.5+)_
