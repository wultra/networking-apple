# Networking Apple code review

Review only the pull request diff. First establish the repository, PR target branch,
head branch, and current checkout; do not infer them from the working tree. This
repository is **WultraPowerAuthNetworking**, an iOS 13+/tvOS 13+ Swift 5 library.
It ships both `Package.swift` product `WultraPowerAuthNetworking` and
`WultraPowerAuthNetworking.podspec`. Sources deliberately live at
`Sources/WultraPowerauthNetworking` (lowercase `a`); do not suggest changing that
historical path's case in isolation.

## Review outcome and comments

- Default to approval. Report only a concrete, reproducible regression introduced by
  the PR, with its `path:line`, user/security impact, and a specific correction.
- Do not make speculative findings, summaries, praise, style/formatting/naming
  comments, or CI/tooling advice. Do not ask for tests merely as a preference.
- Review public documentation and changelog coverage for externally observable API,
  integration, compatibility, or release changes. Grammar/spelling is reviewable
  only in public documentation or public Swift documentation comments, and only
  when the PR base is **not** `release/*`.
- Never post a review, comment, approval, or any GitHub content without explicit
  user approval. Any content suitable for posting must start with `🤖`.

## API and transport contract

Public API is concentrated in `WPNNetworkingService`, `WPNEndpoint.swift`,
`WPNConfig.swift`, `WPNBaseNetworkingObjects.swift`, `WPNError.swift`,
`WPNResponseDelegate.swift`, `WPNInterceptor.swift`,
`WPNSSLValidationStrategy.swift`, `WPNEncryptorScope.swift`, and `WPNLogger.swift`.
Treat source/binary compatibility of the endpoint generic types
(`WPNEndpointBasic`, `WPNEndpointAuthenticated`,
`WPNEndpointAuthenticatedWithToken`), `post` overloads, error reasons, response
envelopes, interceptor, pinning, and logger APIs as public contract changes.

The protocol is POST-only. Request types derive from `WPNRequestBase`; response
types derive from `WPNResponseBase` or use `WPNResponse<T>` /
`WPNResponseArray<T>`. Preserve the `requestObject`, `responseObject`, and
`status` envelope semantics: only decoded `.Ok` succeeds; malformed successful
HTTP bodies become `network_invalidResponseObject`; backend errors remain
`WPNRestApiError`.

Security-sensitive changes require a demonstrated flaw, not generic hardening
advice. Trace `WPNNetworkingService.swift`, `WPNHttpRequests.swift`,
`WPNHttpClient.swift`, and `WPNSSLValidationStrategy.swift` for:

- PowerAuth signing versus token authentication and activation preconditions;
- ECIES scope selection, cryptogram envelope encoding, and response decryption;
- TLS challenge disposition and pinning-provider failure behavior;
- request interceptor effects after signing/encryption; and
- accidental logging of authorization, cryptograms, tokens, or plaintext through
  `WPNLogger` / `HeaderBlockList`.

Do not approve a change that demonstrably bypasses signing, changes E2EE scope,
weakens TLS validation, exposes secrets, or silently changes date/JSON wire
format. The defaults are custom fractional-second ISO-8601 decoding and ISO-8601
encoding, `acceptLanguage == "en"`, and non-persisted language selection.

## Concurrency and completion behavior

`WPNNetworkingService` serializes authenticated PowerAuth work through
`PowerAuthSDK.executeOperation(onSerialQueue:)`; unauthenticated work uses its
operation queue unless `.concurrentAll` is selected. Check changed paths for
proven races, double/missing completion, lost cancellation, or an operation never
being finished. Callback `completionQueue` defaults to `.main` and must remain
honored. The async `post` overloads must preserve callback behavior, surface the
same `WPNError`, resume exactly once, and connect Swift task cancellation to the
underlying `Operation`.

## Versions, documentation, and validation

For a release PR, `.prepare-release.json` requires matching version work in
`WultraPowerAuthNetworking.podspec`,
`Sources/WultraPowerauthNetworking/WPNConstants.swift`, and the compatibility and
`### version` changelog sections of `README.md`. For a release merged back to
`develop`, every declared development version must be `0.0.1-dev`, including the
podspec and `WPNConstants.sdkVersionName`; flag a different declared version.
Do not require release metadata for ordinary feature PRs.

Relevant tests are in `WultraPowerAuthNetworkingTests/UnitTests` and
`IntegrationTests`, using `TestUtils.createFakeService()`. The project’s actual
validation is `scripts/swiftlint.sh`, `scripts/build.sh`, and `scripts/test.sh`
against `WultraPowerAuthNetworking.xcodeproj`; CI selects Xcode through
`scripts/xcodeselect.sh`. Treat test changes as evidence when assessing a proven
behavioral regression, not as a checklist item.
