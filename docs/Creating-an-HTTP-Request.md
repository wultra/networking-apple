# Creating an HTTP Request

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
