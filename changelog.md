# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.1] - TBD

### Changed
- Changed `WPNRequestBase` from `Codable` to `Encodable` only, reducing constraints on integrators
- Changed `WPNRequest<T>` generic parameter constraint from `Codable` to `Encodable` only
- Removed unused `init(from decoder:)` method from `WPNRequest` class

### Benefits
- Reduces boilerplate code for integrators who no longer need to implement unnecessary `Decodable` conformance
- Makes the API intent clearer (requests are only sent, not received)
- Maintains full backward compatibility
- Keeps response types as `Codable` (which need both encoding and decoding)

## [1.5.0] - Previous Release
- Previous changes before changelog was introduced