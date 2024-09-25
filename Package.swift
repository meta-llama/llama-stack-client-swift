// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LlamaStackClient",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "LlamaStackClient",
      targets: ["LlamaStackClient"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-urlsession.git", from: "1.0.2"),
    .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "LlamaStackClient",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]),
    .testTarget(
      name: "LlamaStackClientTests",
      dependencies: ["LlamaStackClient"]),
  ]
)
