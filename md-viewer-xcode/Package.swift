// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "md-viewer",
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main")
    ]
)
