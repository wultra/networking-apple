# Language Configuration

Before using any SDK methods that call the backend, you should set the proper language. Properly translated content is served based on this configuration. This setting __does not persist__, so you need to set `acceptLanguage` every time the application starts.

<!-- begin box warning -->
Note: Content-language capabilities are limited by the server implementation - the server must support the provided language.
<!-- end -->

## Format

The default value is always `en`. For other languages, use values compliant with the standard RFC [Accept-Language](https://tools.ietf.org/html/rfc7231#section-5.3.5).
