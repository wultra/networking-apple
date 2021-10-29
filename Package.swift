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
        .package(name: "PowerAuth2", url: "https://github.com/wultra/powerauth-mobile-sdk-spm.git", .branch("develop"))
    ],
    targets: [
        .target(
            name: "WultraPowerAuthNetworking",
            dependencies: ["PowerAuth2", .product(name: "PowerAuthCore", package: "PowerAuth2")])
    ]
)
