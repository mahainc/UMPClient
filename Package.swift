// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UMPClient",
    // Raised with AnalyticsClient 2.0.0, which is iOS 17+. The only consumer,
    // ConsentClient, already targets iOS 17.
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .singleTargetLibrary("UMPClient"),
        .singleTargetLibrary("UMPClientLive"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies.git",
            from: "1.9.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-case-paths.git",
            from: "1.5.0"
        ),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git", from: "3.0.0"),
        .package(url: "https://github.com/mahainc/AnalyticsClient.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "UMPClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
            ]
        ),
        .target(
            name: "UMPClientLive",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
                "UMPClient",
                "AnalyticsClient",
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
