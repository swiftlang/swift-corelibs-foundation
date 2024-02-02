// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let buildSettings: [CSetting] = [
    .headerSearchPath("internalInclude"),
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("__CONSTANT_CFSTRINGS__"),
    .define("_GNU_SOURCE", .when(platforms: [.linux, .android])),
    .define("CF_CHARACTERSET_UNICODE_DATA_L", to: "\"Sources/CoreFoundation/CFUnicodeData-L.mapping\""),
    .define("CF_CHARACTERSET_UNICODE_DATA_B", to: "\"Sources/CoreFoundation/CFUnicodeData-B.mapping\""),
    .define("CF_CHARACTERSET_UNICHAR_DB", to: "\"Sources/CoreFoundation/CFUniCharPropertyDatabase.data\""),
    .define("CF_CHARACTERSET_BITMAP", to: "\"Sources/CoreFoundation/CFCharacterSetBitmaps.bitmap\""),
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        "-Wno-deprecated-declarations",
        "-Wno-unreachable-code",
        "-Wno-conditional-uninitialized",
        "-Wno-unused-variable",
        "-Wno-int-conversion",
        "-Wno-unused-function",
        "-Wno-microsoft-enum-forward-reference",
        "-fconstant-cfstrings", 
        "-fexceptions", // TODO: not on OpenBSD
        "-fdollars-in-identifiers",
        "-fno-common",
        "-fcf-runtime-abi=swift"
        // /EHsc for Windows
    ]),
    .unsafeFlags(["-I/usr/lib/swift"])
]

let package = Package(
    name: "swift-corelibs-foundation",
    products: [
        .library(name: "Foundation", targets: ["Foundation"]),
        .executable(name: "plutil", targets: ["plutil"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-foundation-icu",
            exact: "0.0.5"),
        .package(
            // url: "https://github.com/apple/swift-foundation",
            // branch: "main"
            path: "../swift-foundation"
        )
    ],
    targets: [
        .target(
            name: "Foundation",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                .product(name: "FoundationInternationalization", package: "swift-foundation"),
                "CoreFoundationPackage"
            ],
            path: "Sources/Foundation",
            swiftSettings: [.define("DEPLOYMENT_RUNTIME_SWIFT")]
        ),
        .target(
            name: "CoreFoundationPackage",
            dependencies: [
                .product(name: "FoundationICU", package: "swift-foundation-icu"),
                "Clibxml2"
            ],
            path: "Sources/CoreFoundation",
            exclude: ["CFURLSessionInterface.c"], // TODO: Need curl
            cSettings: buildSettings
        ),
        .systemLibrary(
            name: "Clibxml2",
            pkgConfig: "libxml-2.0",
            providers: [
                .brew(["libxml2"]),
                .apt(["libxml2-dev"])
            ]
        ),
        .executableTarget(
            name: "plutil",
            dependencies: ["Foundation"]
        )
    ]
)
