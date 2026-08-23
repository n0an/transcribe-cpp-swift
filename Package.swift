// swift-tools-version: 5.9
import PackageDescription

// TranscribeCpp - Swift bindings for transcribe.cpp.
//
// The Swift sources under Sources/TranscribeCpp are copied verbatim from
// upstream; the native library is consumed as a prebuilt xcframework published
// as a release asset on this repository. See UPSTREAM.md for the pinned source
// commit, the build command that produced the asset, and its checksum.
//
// macOS only: the published xcframework carries a single universal
// arm64 + x86_64 macOS slice (Metal on arm64, CPU-only on x86_64).

let package = Package(
    name: "transcribe-cpp-swift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TranscribeCpp", targets: ["TranscribeCpp"])
    ],
    targets: [
        // Raw C surface. The module name comes from the module map bundled in
        // the framework, so the Swift wrapper does `import CTranscribe`.
        .binaryTarget(
            name: "CTranscribe",
            url: "https://github.com/n0an/transcribe-cpp-swift/releases/download/0.2.1/TranscribeCpp.xcframework.zip",
            checksum: "b348a496c1bdc17a9e6bb712696dc008b7110af28017611a15a5ed8d9a4b9737"
        ),

        // The idiomatic Swift wrapper. These are the system libraries and
        // frameworks the merged static archive does not carry itself.
        .target(
            name: "TranscribeCpp",
            dependencies: ["CTranscribe"],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("Accelerate"),
                .linkedFramework("Foundation"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
            ]
        ),

        .testTarget(
            name: "TranscribeCppTests",
            dependencies: ["TranscribeCpp"]
        ),
    ]
)
