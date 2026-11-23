# Error Handling

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

## WPNErrorReason

Each `WPNError` has a `reason` property that explains why the error was created. This can be useful when you are creating, for example, general error-handling or reporting logic, or when you are debugging the code.

### General errors

| Option Name | Description |
|---|---|
|`unknown`|Unknown fallback reason|
|`missingActivation`|PowerAuth instance is missing an activation.|

### Network errors

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

### Custom Errors

`WPNErrorReason` is a struct that can also be created by other libraries, so the list above is not exhaustive. Such errors (in libraries developed by Wultra) are documented in their respective documentation, for example in the Mobile Token SDK documentation.
