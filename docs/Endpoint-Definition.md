# Endpoint Definition

Each endpoint you target in your project must be defined for the service as a `WPNEndpoint` instance. There are several endpoint types, depending on the required PowerAuth authentication.

## End To End Encryption

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

## Authenticated endpoint `WPNEndpointAuthenticated`

For endpoints that use a __PowerAuth authentication code__ and can be end-to-end encrypted.

Example:

```swift
typealias MyAuthenticatedEndpointType = WPNEndpointAuthenticated<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myAuthenticatedEndpoint: MyAuthenticatedEndpointType { WPNEndpointAuthenticated(endpointURLPath: "/additional/path/to/the/authenticated/endpoint", uriId: "endpoint/identifier", e2ee: .notEncrypted) }
// uriId is defined by the endpoint issuer - ask your server developer/provider

```

## Authenticated endpoint with Token `WPNEndpointAuthenticatedWithToken`

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

## Basic endpoint (not authenticated) `WPNEndpointBasic`

For endpoints that __do not use a PowerAuth authentication code__ but can still be end-to-end encrypted.

Example:

```swift
typealias MyBasicEndpointType = WPNEndpointBasic<WPNRequest<MyEndpointDataRequest>, WPNResponse<MyEndpointDataResponse>>
var myBasicEndpoint: MyBasicEndpointType { WPNEndpointBasic(endpointURLPath: "/additional/path/to/the/basic/endpoint", e2ee: .notEncrypted) }

```
