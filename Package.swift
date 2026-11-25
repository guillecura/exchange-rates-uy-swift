// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExchangeRatesUY",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "ExchangeRatesUY", targets: ["ExchangeRatesUY"]),
    ],
    targets: [
        .target(name: "ExchangeRatesUY"),
        .testTarget(name: "ExchangeRatesUYTests", dependencies: ["ExchangeRatesUY"]),
    ]
)
