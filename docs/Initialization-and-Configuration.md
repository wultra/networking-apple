# Initialization and Configuration

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
        sslValidation: .default, // use default SSL error handling
        timeoutIntervalForRequest: 10, // give 10 seconds for the server to respond
        userAgent: .libraryDefault, // use library default HTTP User-Agent header
        requestInterceptors: [] // interceptors for the final request

    ),
    serviceName: "MyProjectNetworkingService", // for better debugging
    acceptLanguage: "en"
)
```

See also [SSL validation](Networking-Configuration.md#ssl-validation), [Request Interceptors](Networking-Configuration.md#request-interceptors), and [Language Configuration](Language-Configuration.md).
