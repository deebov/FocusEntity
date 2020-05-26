// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FocusEntity",
    platforms: [.iOS("13.0")],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "FocusEntity",
            targets: ["FocusEntity"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FocusEntity",
            dependencies: [])
    ],
    swiftLanguageVersions: [.v5]
)
