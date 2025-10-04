// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "md-viewer",
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "md-viewer",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "md-viewer"
        )
    ]
)