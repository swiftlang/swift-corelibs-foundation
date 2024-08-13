// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let platformsWithThreads: [Platform] = [
    .iOS,
    .macOS,
    .tvOS,
    .watchOS,
    .macCatalyst,
    .driverKit,
    .android,
    .linux,
    .windows,
]

var dispatchIncludeFlags: [CSetting] = []
if let environmentPath = Context.environment["DISPATCH_INCLUDE_PATH"] {
    dispatchIncludeFlags.append(.unsafeFlags([
        "-I\(environmentPath)",
        "-I\(environmentPath)/Block"
    ]))
} else {
    dispatchIncludeFlags.append(
        .unsafeFlags([
            "-I/usr/lib/swift",
            "-I/usr/lib/swift/Block"
        ], .when(platforms: [.linux, .android]))
    )
    if let sdkRoot = Context.environment["SDKROOT"] {
        dispatchIncludeFlags.append(.unsafeFlags([
            "-I\(sdkRoot)usr\\include",
            "-I\(sdkRoot)usr\\include\\Block",
        ], .when(platforms: [.windows])))
    }
}

var libxmlIncludeFlags: [CSetting] = []
if let environmentPath = Context.environment["LIBXML_INCLUDE_PATH"] {
    libxmlIncludeFlags = [
        .unsafeFlags([
            "-I\(environmentPath)"
        ]),
        .define("LIBXML_STATIC")
    ]
}

var curlIncludeFlags: [CSetting] = []
if let environmentPath = Context.environment["CURL_INCLUDE_PATH"] {
    curlIncludeFlags  = [
        .unsafeFlags([
            "-I\(environmentPath)"
        ]),
        .define("CURL_STATICLIB")
    ]
}

var curlLinkFlags: [LinkerSetting] = [
    .linkedLibrary("libcurl.lib", .when(platforms: [.windows])),
    .linkedLibrary("zlibstatic.lib", .when(platforms: [.windows]))
]
if let environmentPath = Context.environment["CURL_LIBRARY_PATH"] {
    curlLinkFlags.append(.unsafeFlags([
        "-L\(environmentPath)"
    ]))
}
if let environmentPath = Context.environment["ZLIB_LIBRARY_PATH"] {
    curlLinkFlags.append(.unsafeFlags([
        "-L\(environmentPath)"
    ]))
}

var libxmlLinkFlags: [LinkerSetting] = [
    .linkedLibrary("libxml2s.lib", .when(platforms: [.windows]))
]
if let environmentPath = Context.environment["LIBXML2_LIBRARY_PATH"] {
    libxmlLinkFlags.append(.unsafeFlags([
        "-L\(environmentPath)"
    ]))
}

let coreFoundationBuildSettings: [CSetting] = [
    .headerSearchPath("internalInclude"),
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("CF_WINDOWS_EXECUTABLE_INITIALIZER", .when(platforms: [.windows])), // Ensure __CFInitialize is run even when statically linked into an executable
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH", .when(platforms: platformsWithThreads)),
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS", .when(platforms: platformsWithThreads)),
    .define("_GNU_SOURCE", .when(platforms: [.linux, .android])),
    .define("_WASI_EMULATED_SIGNAL", .when(platforms: [.wasi])),
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        "-Wno-deprecated-declarations",
        "-Wno-unreachable-code",
        "-Wno-conditional-uninitialized",
        "-Wno-unused-variable",
        "-Wno-unused-function",
        "-Wno-microsoft-enum-forward-reference",
        "-Wno-int-conversion",
        "-Wno-switch",
        "-fconstant-cfstrings",
        "-fexceptions", // TODO: not on OpenBSD
        "-fdollars-in-identifiers",
        "-fno-common",
        "-fcf-runtime-abi=swift",
        "-include",
        "\(Context.packageDirectory)/Sources/CoreFoundation/internalInclude/CoreFoundation_Prefix.h",
        // /EHsc for Windows
    ])
] + dispatchIncludeFlags

// For _CFURLSessionInterface, _CFXMLInterface
let interfaceBuildSettings: [CSetting] = [
    .headerSearchPath("../CoreFoundation/internalInclude"),
    .define("DEBUG", .when(configuration: .debug)),
    .define("CF_BUILDING_CF"),
    .define("DEPLOYMENT_ENABLE_LIBDISPATCH"),
    .define("HAVE_STRUCT_TIMESPEC"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS", .when(platforms: platformsWithThreads)),
    .define("_GNU_SOURCE", .when(platforms: [.linux, .android])),
    .define("_WASI_EMULATED_SIGNAL", .when(platforms: [.wasi])),
    .unsafeFlags([
        "-Wno-shorten-64-to-32",
        "-Wno-deprecated-declarations",
        "-Wno-unreachable-code",
        "-Wno-conditional-uninitialized",
        "-Wno-unused-variable",
        "-Wno-unused-function",
        "-Wno-microsoft-enum-forward-reference",
        "-Wno-int-conversion",
        "-fconstant-cfstrings",
        "-fexceptions", // TODO: not on OpenBSD
        "-fdollars-in-identifiers",
        "-fno-common",
        "-fcf-runtime-abi=swift"
        // /EHsc for Windows
    ])
] + dispatchIncludeFlags

let swiftBuildSettings: [SwiftSetting] = [
    .define("DEPLOYMENT_RUNTIME_SWIFT"),
    .define("SWIFT_CORELIBS_FOUNDATION_HAS_THREADS"),
    .swiftLanguageMode(.v6),
    .unsafeFlags([
        "-Xfrontend",
        "-require-explicit-sendable",
    ])
]

var dependencies: [Package.Dependency] = []

if let useLocalDepsEnv = Context.environment["SWIFTCI_USE_LOCAL_DEPS"] {
    let root: String
    if useLocalDepsEnv == "1" {
        root = ".."
    } else {
        root = useLocalDepsEnv
    }
    dependencies += 
        [
            .package(
                name: "swift-foundation-icu",
                path: "\(root)/swift-foundation-icu"),
            .package(
                name: "swift-foundation",
                path: "\(root)/swift-foundation")
        ]
} else {
    dependencies += 
        [
            .package(
                url: "https://github.com/apple/swift-foundation-icu",
                branch: "main"),
            .package(
                url: "https://github.com/apple/swift-foundation",
                branch: "main")
        ]
}

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
    dependencies: dependencies,
    targets: [
        .target(
            name: "Foundation",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                .product(name: "FoundationInternationalization", package: "swift-foundation"),
                "CoreFoundation"
            ],
            path: "Sources/Foundation",
            exclude: [
                "CMakeLists.txt"
            ],
            swiftSettings: swiftBuildSettings
        ),
        .target(
            name: "FoundationXML",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                "Foundation",
                "CoreFoundation",
                "_CFXMLInterface",
                .target(name: "BlocksRuntime", condition: .when(platforms: [.wasi])),
            ],
            path: "Sources/FoundationXML",
            exclude: [
                "CMakeLists.txt"
            ],
            swiftSettings: swiftBuildSettings
        ),
        .target(
            name: "FoundationNetworking",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation"),
                "Foundation",
                "CoreFoundation",
                "_CFURLSessionInterface"
            ],
            path: "Sources/FoundationNetworking",
            exclude: [
                "CMakeLists.txt"
            ],
            swiftSettings: swiftBuildSettings
        ),
        .target(
            name: "CoreFoundation",
            dependencies: [
                .product(name: "_FoundationICU", package: "swift-foundation-icu"),
                .target(name: "BlocksRuntime", condition: .when(platforms: [.wasi])),
            ],
            path: "Sources/CoreFoundation",
            exclude: [
                "BlockRuntime",
                "CMakeLists.txt"
            ],
            cSettings: coreFoundationBuildSettings
        ),
        .target(
            name: "BlocksRuntime",
            path: "Sources/CoreFoundation/BlockRuntime",
            exclude: [
                "CMakeLists.txt"
            ],
            cSettings: [
                // For CFTargetConditionals.h
                .headerSearchPath("../include"),
            ]
        ),
        .target(
            name: "_CFXMLInterface",
            dependencies: [
                "CoreFoundation",
                .target(name: "Clibxml2", condition: .when(platforms: [.linux])),
            ],
            path: "Sources/_CFXMLInterface",
            exclude: [
                "CMakeLists.txt"
            ],
            cSettings: interfaceBuildSettings + libxmlIncludeFlags,
            linkerSettings: libxmlLinkFlags
        ),
        .target(
            name: "_CFURLSessionInterface",
            dependencies: [
                "CoreFoundation",
                .target(name: "Clibcurl", condition: .when(platforms: [.linux])),
            ],
            path: "Sources/_CFURLSessionInterface",
            exclude: [
                "CMakeLists.txt"
            ],
            cSettings: interfaceBuildSettings + curlIncludeFlags,
            linkerSettings: curlLinkFlags
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
                "Foundation"
            ],
            exclude: [
                "CMakeLists.txt"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "xdgTestHelper",
            dependencies: [
                "Foundation",
                "FoundationXML",
                "FoundationNetworking"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .target(
            // swift-corelibs-foundation has a copy of XCTest's sources so:
            // (1) we do not depend on the toolchain's XCTest, which depends on toolchain's Foundation, which we cannot pull in at the same time as a Foundation package
            // (2) we do not depend on a swift-corelibs-xctest Swift package, which depends on Foundation, which causes a circular dependency in swiftpm
            // We believe Foundation is the only project that needs to take this rather drastic measure.
            name: "XCTest",
            dependencies: [
                "Foundation"
            ],
            path: "Sources/XCTest"
        ),
        .testTarget(
            name: "TestFoundation",
            dependencies: [
                "Foundation",
                "FoundationXML",
                "FoundationNetworking",
                "XCTest",
                .target(name: "xdgTestHelper", condition: .when(platforms: [.linux]))
            ],
            resources: [
                .copy("Foundation/Resources")
            ],
            swiftSettings: [
                .define("NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT"),
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
