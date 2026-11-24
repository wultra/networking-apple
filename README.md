# PowerAuth Networking SDK for Apple platforms

<!-- begin remove -->
<p align="center"><img src="docs/intro.jpg" alt="PowerAuth Networking SDK for Apple platforms" width="100%" /></p>

[![build](https://github.com/wultra/networking-apple/actions/workflows/build.yml/badge.svg)](https://github.com/wultra/networking-apple/actions/workflows/build.yml) [![tests](https://github.com/wultra/networking-apple/actions/workflows/tests.yml/badge.svg)](https://github.com/wultra/networking-apple/actions/workflows/tests.yml) ![spm](https://img.shields.io/github/v/release/wultra/networking-apple?color=F05138&label=SPM) [![pod](https://img.shields.io/cocoapods/v/WultraPowerAuthNetworking)](https://cocoapods.org/pods/WultraPowerAuthNetworking) ![date](https://img.shields.io/github/release-date/wultra/networking-apple) [![license](https://img.shields.io/github/license/wultra/networking-apple)](LICENSE)
<!-- end -->

## Introduction

__Wultra PowerAuth Networking__ (WPN) is a focused networking layer for Apple apps built on top of the [PowerAuth SDK](https://github.com/wultra/powerauth-mobile-sdk). It gives you a clean, consistent way to call protected APIs with PowerAuth authorization, and optional end-to-end encryption.

Think of WPN as a ready-to-use __HTTP client for PowerAuth-based backends__ — designed around the recommended integration model, so you can ship secure networking with less boilerplate and more predictable behavior.

We use this SDK in our other open-source projects. You can use these as inspiration, for example:  
- [Digital Onboarding SDK](https://github.com/wultra/digital-onboarding-apple/blob/develop/Sources/API/Networking.swift)  
- [Mobile Token SDK](https://github.com/wultra/mtoken-sdk-ios/blob/develop/WultraMobileTokenSDK/Operations/Service/WMTOperationsImpl.swift#L259)

## Documentation

The documentation is available at the [Wultra Developer Portal](https://developers.wultra.com/components/networking-apple/) or in the [docs folder](docs/Readme.md).

## License

All sources are licensed using the Apache 2.0 license. You can use them with no restrictions. If you are using this library, please let us know. We will be happy to share and promote your project.

## Contact

If you need any assistance, do not hesitate to drop us a line at [hello@wultra.com](mailto:hello@wultra.com) or our official [wultra.com/discord](https://wultra.com/discord) channel.

### Security Disclosure

If you believe you have identified a security vulnerability with this SDK, you should report it as soon as possible via email to [support@wultra.com](mailto:support@wultra.com). Please do not post it to a public issue tracker.
