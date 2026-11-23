# SDK Integration

## Requirements

- iOS 15.0+ and tvOS 15.0+
- [PowerAuth Mobile SDK](https://github.com/wultra/powerauth-mobile-sdk) must already be integrated into your project

## Swift Package Manager

Add the `https://github.com/wultra/networking-apple` repository as a package in the Xcode UI and add the `WultraPowerAuthNetworking` library as a dependency.

Alternatively, you can add the dependency manually. For example:

```swift
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "YourLibrary",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "YourLibrary",
            targets: ["YourLibrary"]
        ),
    ],
    dependencies: [
        // Replace VERSION_DEFINITION with the actual package version.
        .package(url: "https://github.com/wultra/networking-apple.git", .from("VERSION_DEFINITION"))
    ],
    targets: [
        .target(
            name: "YourLibrary",
            dependencies: ["WultraPowerAuthNetworking"]
        )
    ]
)
```

## CocoaPods

> [!NOTE]
> CocoaPods is [moving to maintenance mode only](https://blog.cocoapods.org/CocoaPods-Support-Plans/). We recommend using Swift Package Manager instead.

Add the following dependency to your Podfile:

```rb
# CocoaPods integration currently targets iOS.
platform :ios, '15.0'

pod 'WultraPowerAuthNetworking'
```

## Xcode Compatibility

We recommend using Xcode version 26.0 or newer.

## Open Source Code

The library is open source, and you can freely browse it on GitHub at [https://github.com/wultra/networking-apple](https://github.com/wultra/networking-apple/#docucheck-keep-link)
