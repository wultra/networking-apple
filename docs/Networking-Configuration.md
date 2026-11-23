# Networking Configuration

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

You can modify the final `URLRequest` right before it is sent via `URLSession` by configuring the `WPNConfig.requestInterceptors` property. Interceptors are applied in declaration order, after headers, PowerAuth authorization, E2EE encryption, and the request body were already set, and the request is logged (see [Logging](Logging.md)) afterwards.

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
