// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let coreFoundationBuildSettings: [CSetting] = [
    .headerSearchPath("internalInclude"),
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH"),
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS"),
    .define("_GNU_SOURCE", .when(platforms: [.linux, .android])),
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        "-Wno-deprecated-declarations",
        "-Wno-unreachable-code",
        "-Wno-conditional-uninitialized",
        "-Wno-unused-variable",
        "-Wno-unused-function",
        "-Wno-microsoft-enum-forward-reference",
        "-fconstant-cfstrings",
        "-fexceptions", // TODO: not on OpenBSD
        "-fdollars-in-identifiers",
        "-fno-common",
        "-fcf-runtime-abi=swift",
        "-include",
        "\(Context.packageDirectory)/Sources/CoreFoundation/internalInclude/CoreFoundation_Prefix.h",
        // /EHsc for Windows
    ]),
    .unsafeFlags(["-I/usr/lib/swift"], .when(platforms: [.linux, .android])) // dispatch
]

// For _CFURLSessionInterface, _CFXMLInterface
let interfaceBuildSettings: [CSetting] = [
    .headerSearchPath("../CoreFoundation/internalInclude"),
    .headerSearchPath("../CoreFoundation/include"),
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS"),
    .define("_GNU_SOURCE", .when(platforms: [.linux, .android])),
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        "-Wno-deprecated-declarations",
        "-Wno-unreachable-code",
        "-Wno-conditional-uninitialized",
        "-Wno-unused-variable",
        "-Wno-unused-function",
        "-Wno-microsoft-enum-forward-reference",
        "-fconstant-cfstrings",
        "-fexceptions", // TODO: not on OpenBSD
        "-fdollars-in-identifiers",
        "-fno-common",
        "-fcf-runtime-abi=swift"
        // /EHsc for Windows
    ]),
    .unsafeFlags(["-I/usr/lib/swift"], .when(platforms: [.linux, .android])) // dispatch
]

let swiftBuildSettings: [SwiftSetting] = [
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS"),
]

let package = Package(
    name: "swift-corelibs-foundation",
    // Deployment target note: This package only builds for non-Darwin targets.
    platforms: [.macOS("99.9")],
    products: [
        .library(name: "Foundation", targets: ["Foundation"]),
        .library(name: "FoundationXML", targets: ["FoundationXML"]),
        .library(name: "FoundationNetworking", targets: ["FoundationNetworking"]),
        .executable(name: "plutil", targets: ["plutil"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-foundation-icu",
            from: "0.0.5"
        ),
        .package(
           url: "https://github.com/apple/swift-foundation",
           revision: "e991656bd02af48530811f1871b3351961b75d29"
        ),
    ],
    targets: [
        .target(
            name: "Foundation",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                .product(name: "FoundationInternationalization", package: "swift-foundation"),
                "_CoreFoundation"
            ],
            path: "Sources/Foundation",
            swiftSettings: swiftBuildSettings
        ),
        .target(
            name: "FoundationXML",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                .targetItem(name: "Foundation", condition: nil),
                "_CoreFoundation",
                "_CFXMLInterface"
            ],
            path: "Sources/FoundationXML",
            swiftSettings: swiftBuildSettings
        ),
        .target(
            name: "FoundationNetworking",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                .targetItem(name: "Foundation", condition: nil),
                "_CoreFoundation",
                "_CFURLSessionInterface"
            ],
            path: "Sources/FoundationNetworking",
            swiftSettings:swiftBuildSettings
        ),
        .target(
            name: "_CoreFoundation",
            dependencies: [
                .product(name: "FoundationICU", package: "swift-foundation-icu"),
            ],
            path: "Sources/CoreFoundation",
            cSettings: coreFoundationBuildSettings
        ),
        .target(
            name: "_CFXMLInterface",
            dependencies: [
                "_CoreFoundation",
                "Clibxml2",
            ],
            path: "Sources/_CFXMLInterface",
            cSettings: interfaceBuildSettings
        ),
        .target(
            name: "_CFURLSessionInterface",
            dependencies: [
                "_CoreFoundation",
                "Clibcurl",
            ],
            path: "Sources/_CFURLSessionInterface",
            cSettings: interfaceBuildSettings
        ),
        .systemLibrary(
            name: "Clibxml2",
            pkgConfig: "libxml-2.0",
            providers: [
                .brew(["libxml2"]),
                .apt(["libxml2-dev"])
            ]
        ),
        .systemLibrary(
            name: "Clibcurl",
            pkgConfig: "libcurl",
            providers: [
                .brew(["libcurl"]),
                .apt(["libcurl"])
            ]
        ),
        .executableTarget(
            name: "plutil",
            dependencies: [
                .targetItem(name: "Foundation", condition: nil)
            ]
        ),
        .executableTarget(
            name: "xdgTestHelper",
            dependencies: [
                .targetItem(name: "Foundation", condition: nil),
                .targetItem(name: "FoundationXML", condition: nil),
                .targetItem(name: "FoundationNetworking", condition: nil)
            ]
        ),
        .target(
            // swift-corelibs-foundation has a copy of XCTest's sources so:
            // (1) we do not depend on the toolchain's XCTest, which depends on toolchain's Foundation, which we cannot pull in at the same time as a Foundation package
            // (2) we do not depend on a swift-corelibs-xctest Swift package, which depends on Foundation, which causes a circular dependency in swiftpm
            // We believe Foundation is the only project that needs to take this rather drastic measure.
            name: "XCTest",
            dependencies: [
                .targetItem(name: "Foundation", condition: nil)
            ],
            path: "Sources/XCTest"
        ),
        .testTarget(
            name: "TestFoundation",
            dependencies: [
                .targetItem(name: "Foundation", condition: nil),
                .targetItem(name: "FoundationXML", condition: nil),
                .targetItem(name: "FoundationNetworking", condition: nil),
                .targetItem(name: "XCTest", condition: .when(platforms: [.linux])),
                "xdgTestHelper"
            ],
            resources: [
                .copy("Foundation/Resources")
            ],
            swiftSettings: [
                .define("NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT")
            ]
        ),
    ]
)
