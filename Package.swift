// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "QueueSQS",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
        // 🧻 Queue.
        .package(url: "https://github.com/vapor/queues.git", from: "1.13.0"),
        // 🎉 A universal SDK for Amazon Web Services.
        .package(url: "https://github.com/soto-project/soto.git", from: "6.7.0"),
        // 🧻 Queue.
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.1.1"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Queues", package: "queues"),
                .product(name: "SotoSQS", package: "soto"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver"),
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
