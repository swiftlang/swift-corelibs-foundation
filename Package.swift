// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let buildSettings: [CSetting] = [
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("__CONSTANT_CFSTRINGS__"),
    .define("_GNU_SOURCE"), // TODO: Linux only?
    .define("CF_CHARACTERSET_UNICODE_DATA_L", to: "\"Sources/CoreFoundation/CFUnicodeData-L.mapping\""),
    .define("CF_CHARACTERSET_UNICODE_DATA_B", to: "\"Sources/CoreFoundation/CFUnicodeData-B.mapping\""),
    .define("CF_CHARACTERSET_UNICHAR_DB", to: "\"Sources/CoreFoundation/CFUniCharPropertyDatabase.data\""),
    .define("CF_CHARACTERSET_BITMAP", to: "\"Sources/CoreFoundation/CFCharacterSetBitmaps.bitmap\""),
    .unsafeFlags(["-Wno-int-conversion", "-fconstant-cfstrings", "-fexceptions"]),
    // .headerSearchPath("libxml2"),
    .unsafeFlags(["-I/usr/include/libxml2"]),
    .unsafeFlags(["-I/usr/lib/swift"])
]

let package = Package(
    name: "swift-corelibs-foundation",
    products: [
        .library(
            name: "CoreFoundationPackage",
            targets: ["CoreFoundationPackage"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-foundation-icu",
            exact: "0.0.5"),
    ],
    targets: [
        .target(
            name: "CoreFoundationPackage",
            dependencies: [
                .product(name: "FoundationICU", package: "swift-foundation-icu")
            ],
            path: "Sources/CoreFoundation",
            cSettings: buildSettings
        )       
    ]
)
