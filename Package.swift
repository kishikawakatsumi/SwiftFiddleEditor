// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "SwiftFiddleEditor",
    platforms: [
       .macOS(.v10_15),
    ],
    dependencies: [
        .package(name: "SourceKitLSP", url: "https://github.com/apple/sourcekit-lsp", .branch("main")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "LSPBindings", package: "SourceKitLSP"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
    ]
)
