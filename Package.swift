// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "web3Util",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "web3Util",
            targets: ["web3Util"]),
    ],
    dependencies: [
        // Core dependencies
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/mathwallet/Secp256k1Swift.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "web3Util",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "CSecp256k1", package: "Secp256k1Swift"),
            ]),
        
        .testTarget(
            name: "web3UtilTests",
            dependencies: ["web3Util"]
        ),
    ]
)
