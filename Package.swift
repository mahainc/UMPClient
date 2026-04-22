// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UMPClient",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .singleTargetLibrary("UMPClient"),
        .singleTargetLibrary("UMPClientLive"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", branch: "main"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git", from: "3.0.0"),
        .package(path: "../AnalyticClient"),
    ],
    targets: [
        .target(
            name: "UMPClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "UMPClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
                "UMPClient",
                "AnalyticClient",
            ]
        ),
        .testTarget(
            name: "UMPClientTests",
            dependencies: ["UMPClient"]
        ),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
