// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "WultraPowerAuthNetworking",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "WultraPowerAuthNetworking",
            targets: ["WultraPowerAuthNetworking"])
    ],
    dependencies: [
        .package(name: "PowerAuth2", url: "https://github.com/wultra/powerauth-mobile-sdk-spm.git", .upToNextMinor(from: "1.6.2"))
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
