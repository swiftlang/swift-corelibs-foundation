// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "TestFoundation",
    products: [
        .executable(name: "TestFoundation", targets: ["TestFoundation"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TestFoundation",
            dependencies: [],
            path: "TestFoundation",
            exclude: ["XDGTestHelper.swift", "xdgTestHelper"]
        ),
    ]
)
