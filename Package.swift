// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "WultraPowerAuthNetworking",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "WultraPowerAuthNetworking",
            type: .dynamic,
            targets: ["WultraPowerAuthNetworking"])
    ],
    dependencies: [
        .package(url: "https://github.com/wultra/powerauth-mobile-sdk.git", revision: "2.0.0-rc1")
    ],
    targets: [
        .target(
            name: "WultraPowerAuthNetworking",
            dependencies: [
                .product(name: "PowerAuth2", package: "powerauth-mobile-sdk")
            ],
            // For historical reasons, the folder has a wrong case-sensitive name, so we have to force the path
            // to get rid of swift PM warning.
            path: "Sources/WultraPowerauthNetworking")
    ],
    swiftLanguageVersions: [.v5]
)
