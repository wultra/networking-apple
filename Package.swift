// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "WultraPowerAuthNetworking",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "WultraPowerAuthNetworking",
            type: .dynamic,
            targets: ["WultraPowerAuthNetworking"])
    ],
    dependencies: [
        .package(name: "PowerAuth2", url: "https://github.com/wultra/powerauth-mobile-sdk-spm.git", .upToNextMinor(from: "1.7.3"))
    ],
    targets: [
        .target(
            name: "WultraPowerAuthNetworking",
            dependencies: ["PowerAuth2", .product(name: "PowerAuthCore", package: "PowerAuth2")],
            // For historical reasons, the folder has a wrong case-sensitive name, so we have to force the path
            // to get rid of swift PM warning.
            path: "Sources/WultraPowerauthNetworking")
    ],
    swiftLanguageVersions: [.v5]
)
