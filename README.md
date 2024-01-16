# PowerAuth Networking SDK for Apple platforms

<!-- begin remove -->
<p align="center"><img src="docs/intro.jpg" alt="Wultra Digital Onboarding for Apple Platforms" width="100%" /></p>

[![build](https://github.com/wultra/networking-apple/actions/workflows/build.yml/badge.svg)](https://github.com/wultra/networking-apple/actions/workflows/build.yml) ![spm](https://img.shields.io/github/v/release/wultra/networking-apple?color=F05138&label=Swift%20Package%20Manager) [![pod](https://img.shields.io/cocoapods/v/WultraPowerAuthNetworking)](https://cocoapods.org/pods/WultraPowerAuthNetworking) ![date](https://img.shields.io/github/release-date/wultra/networking-apple) [![license](https://img.shields.io/github/license/wultra/networking-apple)](LICENSE)
<!-- end -->

__Wultra PowerAuth Networking__ (WPN) is a high-level SDK built on top of our [PowerAuth SDK](https://github.com/wultra/powerauth-mobile-sdk) that enables request signing and encryption.

<!-- begin box info -->
You can imagine the purpose of this SDK as an __HTTP layer (client) that enables request signing and encryption__ via PowerAuth SDK based on its recommended implementation.
<!-- end -->

We use this SDK in our other open-source projects that you can take inspiration for example in:  
- [Digital Onboarding SDK](https://github.com/wultra/digital-onboarding-apple/blob/develop/Sources/API/Networking.swift)  
- [Mobile Token SDK](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/Service/WMTOperationsImpl.swift#L259)

## Documentation Content
- [SDK Integration](#sdk-integration)
- [Open Source Code](#open-source-code)
- [Initialization and Configuration](#initialization-and-configuration)
- [Endpoint Definition](#endpoint-definition)
- [Creating an HTTP request](#Creating-an-HTTP-request)
- [Raw Response Observer](#Raw-Response-Observer)
- [Parallel Requests](#parallel-requests)
- [SSL validation](#ssl-validation)
- [Error Handling](#error-handling)
- [Language Configuration](#language-configuration)
- [Logging](#logging)

## SDK Integration

### Requirements

- iOS 12.0+ and tvOS 12.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) needs to be implemented in your project

### Swift Package Manager

Add the `https://github.com/wultra/networking-apple` repository as a package in Xcode UI and add the `WultraPowerAuthNetworking` library as a dependency.

Alternatively, you can add the dependency manually. For example:

```swift
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "YourLibrary",
    platforms: [
        .iOS(.v12)
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

### Cocoapods

Add the following dependencies to your Podfile:

```rb
pod 'WultraPowerAuthNetworking'
```

### Guaranteed PowerAuth Compatibility

| WPN SDK | PowerAuth SDK |  
|---|---|
| `1.0.x` - `1.2.x` | `1.7.x` |
| `1.3.x` | `1.8.x` |

### Xcode Compatibility

We recommend using Xcode version 15.0 or newer.

## Open Source Code

The code of the library is open source and you can freely browse it in our GitHub at [https://github.com/wultra/networking-apple](https://github.com/wultra/networking-apple/tree/develop)

## Initialization and Configuration

Everything you need is packed inside the single `WPNNetworkingService` class that provides all the necessary APIs for your networking.

To successfully create an instance of the service, you need only 2 things:  
- configured `PowerAuthSDK` object  
- configuration of the service (like endpoints base URL)

<!-- begin box info -->
You can create as many instances of the class as you need for your usage.
<!-- end -->

Example:

```swift
let networking = WPNNetworkingService(
    powerAuth: myPowerAuthInstance, // configured PowerAuthSDK instance
    config: WPNConfig(
        baseUrl: "https://sandbox.company.com/my-service", // URL to my PowerAuth based service
        sslValidation: .default, // use default SSL error handling (more in SSL validation docs section)
        timeoutIntervalForRequest: 10, // give 10 seconds for the server to respond
        userAgent: .libraryDefault // use library default HTTP User-Agent header
        
    ), 
    serviceName: "MyProjectNetworkingService", // for better debugging
    acceptLanguage: "en" // more info in "Language Configuration" docs section
)
```

## Endpoint Definition

Each endpoint you will target with your project must be defined for the service as a `WPNEndpoint` instance. There are several types of endpoints based on the PowerAuth signature that is required.

### Signed endpoint `WPNEndpointSigned`

For endpoints that are __signed__ by PowerAuth signature and can be end-to-end encrypted.

Example:

```swift
typealias MySignedEndpointType = WPNEndpointSigned<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var mySignedEndpoint: MySignedEndpointType { WPNEndpointSigned(endpointURLPath: "/additional/path/to/the/signed/endpoint", uriId: "endpoint/identifier") }
// uriId is defined by the endpoint issuer - ask your server developer/provider

```

### Signed endpoint with Token `WPNEndpointSignedWithToken`

For endpoints that are __signed by token__ by PowerAuth signature and can be end-to-end encrypted.

More info for token-based authentication [can be found here](https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#token-based-authentication)

Example:

```swift
typealias MyTokenEndpointType = WPNEndpointSignedWithToken<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myTokenEndpoint: MyTokenEndpointType { WPNEndpointSignedWithToken(endpointURLPath: "/additional/path/to/the/token/signed/endpoint", tokenName: "MyToken") }

// tokenName is the name of the token as stored in the PowerAuthSDK
// more info can be found in the PowerAuthSDK documentation
// https://github.com/wultra/powerauth-mobile-sdk/blob/develop/docs/PowerAuth-SDK-for-iOS.md#token-based-authentication

```

### Basic endpoint (not signed) `WPNEndpointBasic`

For endpoints that are __not signed__ by PowerAuth signature but can be end-to-end encrypted.

Example:

```swift
typealias MyBasicEndpointType = WPNEndpointBasic<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myBasicEndpoint: MyBasicEndpointType { WPNEndpointBasic(endpointURLPath: "/additional/path/to/the/basic/endpoint") }

```

## Creating an HTTP request

To create an HTTP request to your endpoint, you need to call the `WPNNetworkingService.post` method with the following parameters:

- `data` - with the payload of your request
- `auth` - `PowerAuthAuthentication` instance that will sign the request  
  - this parameter is missing for the basic endpoint 
- `endpoint` - an endpoint that will be called
- `headers` - custom HTTP headers, `nil` by default
- `encryptor` - End to End encryptor in case that the encryption is required, `nil` by default
- `timeoutInterval` - timeout interval, `nil` by default. When `nil`, the default configured in `WPNConfig` will be used
- `progressCallback` - callback with percentage progress (values between 0 and 1)
- `completionQueue` - queue that the completion will be called on (main queue by default)
- `completion` - result completion


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
typealias MyEndpointType = WPNEndpointSigned<WPNRequest<MyRequestPayload>, WPNResponse<MyResponse>>
var endpoint: MyEndpointType { WPNEndpointSigned(endpointURLPath: "/path/to/myendpoint", uriId: "myendpoint/identifier") }

// Authentication, for example purposes, expect user PIN 1111
let auth = PowerAuthAuthentication.possessionWithPassword("1111")
            
// WPNNetworkingService instance call
networking.post(
    // create request data
    data: MyEndpointType.RequestData(.init(userID: "12345")),
    // specify endpoint
    to: endpoint,
    // custom HTTP headers
    with: ["MyCustomHeader: "Value"],
    // encrypt with the application scope
    encryptedWith: powerAuth.eciesEncryptorForApplicationScope(),
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

We use system `URLSession` under the hood.

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

By default, the SDK is serializing all signed requests. Meaning that the requests signed with the PowerAuthSDK are put into the queue and executed one by one (meaning that the HTTP request is not made until the previous one is finished). Other requests will be parallel.

This behavior can be changed via `WPNNetworkingService.concurencyStrategy` with the following possible values:

- `serialSigned` - Default behavior. Only requests that need a PowerAuth signature will be put into the serial queue.
- `serialAll` - All requests will be put into a serial queue.
- `concurentAll` - All requests will be put into the concurrent queue. This behavior is not recommended unless you know exactly why you want this.

<!-- begin box info -->
More about this topic can be found in the [PowerAuth documentation](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#request-synchronization).
<!-- end -->

## SSL validation

The SDK uses default system handling of the SSL errors. To be able to ignore SSL errors (for example when your test server does not have a valid SSL certificate) or implement your own SSL pinning, you can configure `WPNConfig.sslValidation` property to get your desired behavior.

Possible values are:

- `default` - Uses default URLSession handling.
- `noValidation` - Trust HTTPS connections with invalid certificates.
- `sslPinning(_ provider: WPNPinningProvider)` - Validates the server certificate with your own logic.

## Error Handling

Every error produced by this library is of a `WPNError` type. This error contains the following information:

- `reason` - A specific reason, why the error happened. For more information see [WPNErrorReason chapter](#wmterrorreason).
- `nestedError` - Original exception/error (if available) that caused this error.
- `httpStatusCode` - If the error is a networking error, this property will provide the HTTP status code of the error.
- `httpUrlResponse` - If the error is a networking error, this will hold the original HTTP response that was received from the backend.
- `restApiError` - If the error is a "well-known" API error, it will be filled here. For all available codes follow [the source code](https://github.com/wultra/networking-apple/blob/develop/Sources/WultraPowerauthNetworking/WPNBaseNetworkingObjects.swift#L130).
- `networkIsNotReachable` - Convenience property, informs about a state where the network is not available (based on the error type).
- `networkConnectionIsNotTrusted` - Convenience property, informs about a TLS error.
- `powerAuthErrorResponse` - If the error was caused by the PowerAuth error, you can retrieve it here.
- `powerAuthRestApiErrorCode` - If the error was caused by the PowerAuth error, the error code of the original error will be available here.

### WPNErrorReason

Each `WPNError` has a `reason` property for why the error was created. Such reason can be useful when you're creating for example a general error handling or reporting, or when you're debugging the code.

#### General errors  

| Option Name | Description |
|---|---|
|`unknown`|Unknown fallback reason|
|`missingActivation`|PowerAuth instance is missing an activation.|

#### Network errors

| Option Name | Description |
|---|---|
|`network_unknown`|When unknown (usually logic error) happened during networking.|
|`network_generic`|When generic networking error happened.|
|`network_errorStatusCode`|HTTP response code was different than 200 (success).`
|`network_invalidResponseObject`|An unexpected response from the server.|
|`network_invalidRequestObject`|Request is not valid. Such an object is not sent to the server.|
|`network_signError`|When the signing of the request failed.|
|`network_timeOut`|Request timed out|
|`network_noInternetConnection`|Not connected to the internet.|
|`network_badServerResponse`|Bad (malformed) HTTP server response. Probably an unexpected HTTP server error.|
|`network_sslError`|SSL error. For detailed information, see the attached error object when available.|

#### Custom Errors

`WPNErrorReason` is a struct that can be created by other libraries so the list above is not a final list of all possible errors. Such errors (in libraries developed by Wultra) will be presented in the dedicated documentation (for example Mobile Token SDK library).

## Language Configuration

Before using any methods from this SDK that call the backend, a proper language should be set. A properly translated content is served based on this configuration. The property that stores language settings __does not persist__. You need to set `acceptLanguage` every time that the application boots.

<!-- begin box warning -->
Note: Content language capabilities are limited by the implementation of the server - it must support the provided language.
<!-- end -->

### Format

The default value is always `en`. With other languages, we use values compliant with standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).

## Logging

For logging purposes `WPNLogger` that prints to the console is used.

<!-- begin box info -->
Note that logging to the console is available only when the library is compiled with the `DEBUG` or `WPN_ENABLE_LOGGING` Swift compile condition.
<!-- end -->

### Verbosity Level

You can limit the amount of logged information via `verboseLevel` property.

| Level | Description |
| --- | --- |
| `off` | Silences all messages. |
| `errors` | Only errors will be printed to the debug console. |
| `warnings` _(default)_ | Errors and warnings will be printed to the debug console. |
| `all` | All messages will be printed to the debug console. |

### Character limit

To prevent huge logs from being printed out, there is a default limit of 12,000 characters per log in place. You can change this via `WPNLogger.characterLimit`.

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