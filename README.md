# PowerAuth Networking SDK for Apple platforms

<!-- begin remove -->
<p align="center"><img src="docs/intro.jpg" alt="Wultra Digital Onboarding for Apple Platforms" width="100%" /></p>

[![build](https://github.com/wultra/networking-apple/actions/workflows/build.yml/badge.svg)](https://github.com/wultra/networking-apple/actions/workflows/build.yml) [![tests](https://github.com/wultra/networking-apple/actions/workflows/tests.yml/badge.svg)](https://github.com/wultra/networking-apple/actions/workflows/tests.yml) ![spm](https://img.shields.io/github/v/release/wultra/networking-apple?color=F05138&label=SPM) [![pod](https://img.shields.io/cocoapods/v/WultraPowerAuthNetworking)](https://cocoapods.org/pods/WultraPowerAuthNetworking) ![date](https://img.shields.io/github/release-date/wultra/networking-apple) [![license](https://img.shields.io/github/license/wultra/networking-apple)](LICENSE)
<!-- end -->

__Wultra PowerAuth Networking__ (WPN) is a focused networking layer for Apple apps built on top of the [PowerAuth SDK](https://github.com/wultra/powerauth-mobile-sdk). It gives you a clean, consistent way to call protected APIs with PowerAuth authorization, and optional end-to-end encryption.

<!-- begin box info -->
Think of WPN as a ready-to-use __HTTP client for PowerAuth-based backends__ — designed around the recommended integration model, so you can ship secure networking with less boilerplate and more predictable behavior.
<!-- end -->

We use this SDK in our other open-source projects. You can use these as inspiration, for example:  
- [Digital Onboarding SDK](https://github.com/wultra/digital-onboarding-apple/blob/develop/Sources/API/Networking.swift)  
- [Mobile Token SDK](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/Service/WMTOperationsImpl.swift#L259)

## Documentation Content
- [SDK Integration](#sdk-integration)
- [Open Source Code](#open-source-code)
- [Initialization and Configuration](#initialization-and-configuration)
- [Endpoint Definition](#endpoint-definition)
- [Creating an HTTP request](#creating-an-http-request)
- [Raw Response Observer](#raw-response-observer)
- [Parallel Requests](#parallel-requests)
- [SSL validation](#ssl-validation)
- [Request Interceptors](#request-interceptors)
- [JSON encoder and decoder](#json-encoder-and-decoder)
- [Error Handling](#error-handling)
- [Language Configuration](#language-configuration)
- [Logging](#logging)
- [Changelog](#changelog)

## SDK Integration

### Requirements

- iOS 13.0+ and tvOS 13.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) must already be integrated into your project

### Swift Package Manager

Add the `https://github.com/wultra/networking-apple` repository as a package in the Xcode UI and add the `WultraPowerAuthNetworking` library as a dependency.

Alternatively, you can add the dependency manually. For example:

```swift
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "YourLibrary",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "YourLibrary",
            targets: ["YourLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/wultra/networking-apple.git", .from("1.3.0"))
    ],
    targets: [
        .target(
            name: "YourLibrary",
            dependencies: ["WultraPowerAuthNetworking"]
        )
    ]
)
```

### CocoaPods

> [!NOTE]
> CocoaPods is [moving to maintenance mode only](https://blog.cocoapods.org/CocoaPods-Support-Plans/). We recommend using Swift Package Manager instead.

Add the following dependency to your Podfile:

```rb
# CocoaPods integration currently targets iOS.
platform :ios, '13.0'

pod 'WultraPowerAuthNetworking'
```

### Xcode Compatibility

We recommend using Xcode version 26.0 or newer.

## Open Source Code

The library is open source, and you can freely browse it on GitHub at [https://github.com/wultra/networking-apple](https://github.com/wultra/networking-apple/#docucheck-keep-link)

## Initialization and Configuration

Everything you need is packed into the single `WPNNetworkingService` class, which provides all the networking APIs you need.

To successfully create an instance of the service, you need only two things:  
- a configured `PowerAuthSDK` object  
- service configuration (such as the base endpoint URL)

<!-- begin box info -->
You can create as many instances of the class as you need for your use case.
<!-- end -->

Example:

```swift
let networking = WPNNetworkingService(
    powerAuth: myPowerAuthInstance, // configured PowerAuthSDK instance
    config: WPNConfig(
        baseUrl: "https://sandbox.company.com/my-service", // URL to my PowerAuth based service
        sslValidation: .default, // use default SSL error handling (more in SSL validation docs section)
        timeoutIntervalForRequest: 10, // give 10 seconds for the server to respond
        userAgent: .libraryDefault, // use library default HTTP User-Agent header
        requestInterceptors: [] // interceptors for the final request, more in "Request Interceptors" docs section
        
    ), 
    serviceName: "MyProjectNetworkingService", // for better debugging
    acceptLanguage: "en" // more info in "Language Configuration" docs section
)
```

## Endpoint Definition

Each endpoint you target in your project must be defined for the service as a `WPNEndpoint` instance. There are several endpoint types, depending on the required PowerAuth authentication.

### End To End Encryption

If the endpoint is end-to-end encrypted, you need to configure it in the initializer. The default initializers use `e2ee: .notEncrypted`.

Possible values are:

```swift
/// Endpoint configuration for end to end encryption.
public enum WPNE2EEConfiguration {
    /// Endpoint is encrypted with the application scope.
    case applicationScope
    /// Endpoint is encrypted with the activation scope.
    case activationScope
    /// Endpoint is not encrypted.
    case notEncrypted
}
```

<!-- begin box info -->
Whether an endpoint is encrypted is determined by its backend definition.
<!-- end -->

### Authenticated endpoint `WPNEndpointAuthenticated`

For endpoints that use a __PowerAuth authentication code__ and can be end-to-end encrypted.

Example:

```swift
typealias MyAuthenticatedEndpointType = WPNEndpointAuthenticated<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myAuthenticatedEndpoint: MyAuthenticatedEndpointType { WPNEndpointAuthenticated(endpointURLPath: "/additional/path/to/the/authenticated/endpoint", uriId: "endpoint/identifier", e2ee: .notEncrypted) }
// uriId is defined by the endpoint issuer - ask your server developer/provider

```

### Authenticated endpoint with Token `WPNEndpointAuthenticatedWithToken`

For endpoints that use a __PowerAuth token authentication__ and can be end-to-end encrypted.

More information about token-based authentication [can be found here](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#token-based-authentication).

Example:

```swift
typealias MyTokenEndpointType = WPNEndpointAuthenticatedWithToken<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myTokenEndpoint: MyTokenEndpointType { WPNEndpointAuthenticatedWithToken(endpointURLPath: "/additional/path/to/the/token/authenticated/endpoint", tokenName: "MyToken", e2ee: .notEncrypted) }

// tokenName is the name of the token as stored in the PowerAuthSDK
// more information can be found in the PowerAuthSDK documentation
// https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#token-based-authentication

```

### Basic endpoint (not authenticated) `WPNEndpointBasic`

For endpoints that __do not use a PowerAuth authentication code__ but can still be end-to-end encrypted.

Example:

```swift
typealias MyBasicEndpointType = WPNEndpointBasic<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myBasicEndpoint: MyBasicEndpointType { WPNEndpointBasic(endpointURLPath: "/additional/path/to/the/basic/endpoint", e2ee: .notEncrypted) }

```

## Creating an HTTP request

To create an HTTP request for your endpoint, you can call either the callback-based `WPNNetworkingService.post` method or its `async` counterpart with the following request parameters:

- `data` - the payload of your request
- `auth` - the `PowerAuthAuthentication` instance used to authenticate the request  
  - this parameter is omitted for the basic endpoint 
- `endpoint` - the endpoint to call
- `headers` - custom HTTP headers, `nil` by default
- `timeoutInterval` - the timeout interval, `nil` by default. When `nil`, the default configured in `WPNConfig` is used
- `progressCallback` - a callback with percentage progress (values between 0 and 1)
- `completionQueue` - the queue on which the completion is called (callback API only, main queue by default)
- `completion` - the result completion handler (callback API only)


Example:

```swift
// payload we will send to the server
struct MyRequestPayload {
    let userID: String
}

// response of the server
struct MyResponse {
    let name: String
    let email: String
}

// endpoint configuration
typealias MyEndpointType = WPNEndpointAuthenticated<WPNRequest<MyRequestPayload>, WPNResponse<MyResponse>>
var endpoint: MyEndpointType { WPNEndpointAuthenticated(endpointURLPath: "/path/to/myendpoint", uriId: "myendpoint/identifier") }

// Authentication (for example purposes) expect user PIN 1111
let auth = PowerAuthAuthentication.possessionWithPassword("1111")
            
// WPNNetworkingService instance call
networking.post(
    // create request data
    data: MyEndpointType.RequestData(.init(userID: "12345")),
    // specify endpoint
    to: endpoint,
    // custom HTTP headers
    with: ["MyCustomHeader": "Value"],
    // only wait 10 seconds at max
    timeoutInterval: 10,
    // handle response or error
    completion: { result, error in
        if let data = result?.responseObject {
            // we have data
        } else {
            // handle error or empty response
        }
    }
)

```

`WultraPowerAuthNetworking` also provides `async/await` counterparts to all public `WPNNetworkingService.post(...)` overloads.

The SDK uses the system `URLSession` under the hood.

## Raw Response Observer

All responses can be observed with `WPNResponseDelegate` in `WPNNetworkingService.responseDelegate`.

An example implementation of the delegate:

```swift
class MyResponseDelegateLogger: WPNResponseDelegate {
    
    func responseReceived(from url: URL, statusCode: Int?, body: Data) {
        print("Response received from \(url) with status code \(statusCode) and data:")
        print(String(data: body, encoding: .utf8) ?? "")
    }
    
    // for endpoints that are end-to-end encrypted
    func encryptedResponseReceived(from url: URL, statusCode: Int?, body: Data, decrypted: Data) {
        print("Encrypted response received from \(url) with status code \(statusCode) and: ")
        print("    Raw data:")
        print(String(data: body, encoding: .utf8) ?? "")
        print("    Decrypted data:")
        print(String(data: decrypted, encoding: .utf8) ?? "")
    }
}
```

## Parallel Requests

By default, the SDK serializes all authenticated requests. Requests authenticated with `PowerAuthSDK` are placed into a queue and executed one by one, which means an HTTP request is not sent until the previous one finishes. Other requests are executed in parallel.

This behavior can be changed via `WPNNetworkingService.concurrencyStrategy` with the following possible values:

- `serialAuthenticated` - Default behavior. Only requests that need a PowerAuth authentication code will be put into the serial queue that is shared with the `PowerAuthSDK` instance to ensure all authenticated requests are in proper order.
- `concurrentAll` - All requests will be put into the concurrent queue. This behavior is not recommended unless you know exactly why you want this.

<!-- begin box info -->
More about this topic can be found in the [PowerAuth documentation](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#request-synchronization).
<!-- end -->

## JSON encoder and decoder

The SDK uses `JSONEncoder` and `JSONDecoder` with `iso8601` date strategies by default.

If the default configuration does not suit your needs, you can assign your own encoder and decoder instances to the `jsonEncoder` and `jsonDecoder` properties of `WPNNetworkingService`. They will then be used for all outbound and inbound traffic.

For more info about the JSON encoding and decoding, visit the official [Apple documentation](https://developer.apple.com/documentation/foundation/archives_and_serialization/using_json_with_custom_types).

## SSL validation

The SDK uses the system's default handling of SSL errors. To ignore SSL errors (for example, when your test server does not have a valid SSL certificate) or implement your own SSL pinning, configure the `WPNConfig.sslValidation` property.

Possible values are:

- `default` - Uses default URLSession handling.
- `noValidation` - Trust HTTPS connections with invalid certificates.
- `sslPinning(_ provider: WPNPinningProvider)` - Validates the server certificate with your own logic.

## Request Interceptors

You can modify the final `URLRequest` right before it is sent via `URLSession` by configuring the `WPNConfig.requestInterceptors` property. Interceptors are applied in declaration order, after headers, PowerAuth authorization, E2EE encryption, and the request body were already set, and the request is logged (see [Logging](#logging)) afterwards.

To create your own interceptor, implement the `WPNInterceptor` protocol:

```swift
public protocol WPNInterceptor {
    func processRequest(_ request: NSMutableURLRequest)
}
```

<!-- begin box warning -->
Don't modify the `X-PowerAuth-*` headers or the request body in an interceptor - doing so could lead to the backend rejecting the request.
<!-- end -->

<!-- begin box info -->
`PowerAuthHttpRequestInterceptor` instances (used by the PowerAuth SDK) can be used here too via their `asWPNInterceptor` property.
<!-- end -->

### Example: adding an X-Correlation-ID header

A common use case is attaching a per-request correlation ID for tracing requests across your backend services:

```swift
class CorrelationIdInterceptor: WPNInterceptor {
    func processRequest(_ request: NSMutableURLRequest) {
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-ID")
    }
}

let config = WPNConfig(
    baseUrl: myBaseUrl,
    requestInterceptors: [CorrelationIdInterceptor()]
)
```

## Error Handling

Every error produced by this library is of type `WPNError`. This error contains the following information:

- `reason` - A specific reason why the error happened. For more information, see the [WPNErrorReason chapter](#wpnerrorreason).
- `nestedError` - The original exception or error (if available) that caused this error.
- `httpStatusCode` - If the error is a networking error, this property will provide the HTTP status code of the error.
- `httpUrlResponse` - If the error is a networking error, this holds the original HTTP response received from the backend.
- `restApiError` - If the error is a "well-known" API error, it will be filled here. For all available codes follow [the source code](https://github.com/wultra/networking-apple/blob/develop/Sources/WultraPowerauthNetworking/WPNBaseNetworkingObjects.swift#L130#docucheck-keep-link).
- `networkIsNotReachable` - Convenience property, informs about a state where the network is unavailable (based on the error type).
- `networkConnectionIsNotTrusted` - Convenience property, informs about a TLS error.
- `powerAuthErrorResponse` - If the error was caused by the PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - If the error was caused by the PowerAuth error, the error code of the original error will be available here.

### WPNErrorReason

Each `WPNError` has a `reason` property that explains why the error was created. This can be useful when you are creating, for example, general error-handling or reporting logic, or when you are debugging the code.

#### General errors  

| Option Name | Description |
|---|---|
|`unknown`|Unknown fallback reason|
|`missingActivation`|PowerAuth instance is missing an activation.|

#### Network errors

| Option Name | Description |
|---|---|
|`network_unknown`|When unknown (usually logic error) happened during networking.|
|`network_generic`|Network error that indicates a generic network issue (for example server internal error).|
|`network_errorStatusCode`|HTTP response code was different than 200 (success).|
|`network_invalidResponseObject`|An unexpected response from the server.|
|`network_invalidRequestObject`|Request is not valid. Such an object is not sent to the server.|
|`network_signError`|When the authentication code computation for the request failed.|
|`network_timeOut`|Request timed out|
|`network_noInternetConnection`|Not connected to the internet.|
|`network_badServerResponse`|Bad (malformed) HTTP server response. Probably an unexpected HTTP server error.|
|`network_sslError`|SSL error. For detailed information, see the attached error object when available.|
|`network_e2eeError`|End-to-end encryption or decryption failed. For detailed information, see the attached error object when available.|
|`network_tokenError`|PowerAuth token authorization failed — the token could not be obtained or its header could not be generated.|

#### Custom Errors

`WPNErrorReason` is a struct that can also be created by other libraries, so the list above is not exhaustive. Such errors (in libraries developed by Wultra) are documented in their respective documentation, for example in the Mobile Token SDK documentation.

## Language Configuration

Before using any SDK methods that call the backend, you should set the proper language. Properly translated content is served based on this configuration. This setting __does not persist__, so you need to set `acceptLanguage` every time the application starts.

<!-- begin box warning -->
Note: Content-language capabilities are limited by the server implementation - the server must support the provided language.
<!-- end -->

### Format

The default value is always `en`. For other languages, use values compliant with the standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

## Logging

You can set up logging for the library using the `WPNLogger` class.

### Verbosity Level

You can limit the amount of logged information via the `verboseLevel` property.

| Level                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| `off`                  | Silences all logs.                                |
| `errors`               | Only errors will be logged.                       |
| `warnings` _(default)_ | Errors and warnings will be logged.               |
| `info`                 | Errors, warnings, and info messages will be logged. |
| `debug`                | All messages will be logged.                      |

### Character limit

To prevent huge logs from being printed, the default limit is 12,000 characters per log. You can change this via `WPNLogger.characterLimit`.

### HTTP traffic logs

- You can turn on or off logging of HTTP requests and responses with the `WPNLogger.logHttpTraffic` property.
- You can filter which headers will be logged with the `WPNLogger.httpHeadersToSkip` property.

### Logger Delegate

If you want to process logs on your own (for example, log them to a file or a cloud service), you can set `WPNLogger.delegate`.

## Changelog

### TBA

- Added `WPNConfig.requestInterceptors` for modifying the final request right before it is sent via `URLSession`. See the [Request Interceptors](#request-interceptors) docs section.

### 2.0.0
- Requires PowerAuth SDK `2.0.0`.
- PowerAuth time is now synchronized before requesting a token-based authorization header, but only when the token is not already cached locally.
- Raised the minimum supported platform versions to iOS 13.0 and tvOS 13.0.
- Added `async/await` counterparts to all public `WPNNetworkingService.post(...)` overloads.
- Added `network_e2eeError` and `network_tokenError` error reasons for more granular error handling.
- Renamed `WPNEndpointSigned` to `WPNEndpointAuthenticated` and `WPNEndpointSignedWithToken` to `WPNEndpointAuthenticatedWithToken` to align with updated PowerAuth terminology (authentication code instead of signature).
- Renamed `WPNRequestConcurrencyStrategy.serialSigned` to `.serialAuthenticated`.
- Renamed the `signedWith` parameter label in `post(...)` methods to `authenticatedWith`.

### 1.5.2
- Time is now always synchronized when creating token-based authorization headers

### 1.5.1
- Added `jsonDecoder` and `jsonEncoder` properties to the `WPNNetworkingService` for custom JSON formatting
- Better `iso8601` date deserialization by default
- Improved async operation state handling + better cancel handling
- Making `WPNRequest` `Encodable` instead of `Codable`

### 1.5.0
- Upgraded PowerAuthSDK to `1.9.x`  _(requires server 1.9+)_
- End-to-end encryption was moved from post functions to the endpoint definition

### 1.4.0
- Log improvements
- Removed the `serialAll` option from concurrency settings

### 1.3.2
- Added new `WPNKnownRestApiError` cases

### 1.3.0
- Upgraded PowerAuthSDK to `1.8.x` _(requires server 1.5+)_

<!-- begin remove -->
## Web Documentation

This documentation is also available at the [Wultra Developer Portal](https://developers.wultra.com/).

## License

All sources are licensed using the Apache 2.0 license. You can use them with no restrictions. If you are using this library, please let us know. We will be happy to share and promote your project.

## Contact

If you need any assistance, do not hesitate to drop us a line at [hello@wultra.com](mailto:hello@wultra.com) or our official [wultra.com/discord](https://wultra.com/discord) channel.

### Security Disclosure

If you believe you have identified a security vulnerability with this SDK, you should report it as soon as possible via email to [support@wultra.com](mailto:support@wultra.com). Please do not post it to a public issue tracker.
<!-- end -->
