# Upstream provenance

This repository is a packaging shell. It contains no original library code: the
Swift sources are copied verbatim from transcribe.cpp, and the binary artifact
is built from a pinned upstream commit. This file records exactly what was
taken, from where, and how the artifact was produced, so any future release can
be reproduced and audited.

## Source

| | |
|---|---|
| Upstream repository | https://github.com/handy-computer/transcribe.cpp |
| Upstream license    | MIT |
| Pinned tag          | `v0.2.1` |
| Pinned commit       | `ea077b87590bcfb090d7c38c03ab36cd1c7005d3` |
| Runtime version     | transcribe.cpp `0.2.1` (`TRANSCRIBE_VERSION_MAJOR/MINOR/PATCH` in `include/transcribe.h`) |

Vendored dependencies inside that commit, both MIT (see
[`THIRD-PARTY-LICENSES.md`](THIRD-PARTY-LICENSES.md)):

| Dependency | Version | Pin |
|---|---|---|
| ggml  | 0.20.2 | `8c63e70982c95ceb862e3a1073a2c1beef75d60a`, plus the downstream patch `patches/ggml/0001-fix-threadpool-oversubscription.patch` |
| miniz | 3.1.1  | `d10b03cc73475af673df40f06e5cefd1d5f940d9` |

## What was copied

| Path here | Path upstream |
|---|---|
| `Sources/TranscribeCpp/` | `bindings/swift/Sources/TranscribeCpp/` |
| `Tests/TranscribeCppTests/` | `bindings/swift/Tests/TranscribeCppTests/` |
| `LICENSE` | `LICENSE` |

The Swift sources and tests are byte-for-byte identical to upstream. Verify at
any time with:

```sh
git clone https://github.com/handy-computer/transcribe.cpp.git /tmp/transcribe.cpp
git -C /tmp/transcribe.cpp checkout ea077b87590bcfb090d7c38c03ab36cd1c7005d3
diff -r /tmp/transcribe.cpp/bindings/swift/Sources/TranscribeCpp Sources/TranscribeCpp
diff -r /tmp/transcribe.cpp/bindings/swift/Tests/TranscribeCppTests Tests/TranscribeCppTests
```

`Package.swift` is not copied. Upstream's manifest also ships five example
executables and an iOS platform; this package declares only the `TranscribeCpp`
library and the macOS platform, because only the macOS slice is built and
published here.

## How the artifact was built

From a clean checkout of the pinned commit, on macOS with Xcode and CMake
installed:

```sh
TRANSCRIBE_XCFRAMEWORK_SLICES=macos ./scripts/ci/build_xcframework.sh
```

That is upstream's own build script, run unmodified. It writes
`bindings/swift/build-apple/TranscribeCpp.xcframework`: one universal
`arm64 + x86_64` macOS slice, containing a dynamic `CTranscribe.framework` with
the merged static `libtranscribe` and `libggml`. Metal is enabled and the
metallib is embedded on `arm64`; the `x86_64` half is CPU-only. Both halves
target macOS 13.0.

Build environment used for the published artifact:

| | |
|---|---|
| Host        | macOS 26.5 (Darwin 25.5.0), Apple Silicon |
| Xcode       | 26.6 (17F113) |
| CMake       | 4.0.3 |
| Generator   | Ninja 1.13.2 (the script prefers Ninja and falls back to Unix Makefiles) |

The `.xcframework` is then packaged, with the three MIT license texts added at
its root so the notices travel with the binary:

```sh
cp LICENSE                            TranscribeCpp.xcframework/LICENSE
cp ggml/LICENSE                       TranscribeCpp.xcframework/LICENSE.ggml
cp src/third_party/miniz/LICENSE      TranscribeCpp.xcframework/LICENSE.miniz
ditto -c -k --keepParent TranscribeCpp.xcframework TranscribeCpp.xcframework.zip
```

Those files sit beside `Info.plist`, outside the signed `.framework` bundle, so
the framework's ad-hoc signature stays valid.

## Published artifact

| | |
|---|---|
| Release tag | `0.2.1` |
| Asset       | `TranscribeCpp.xcframework.zip` |
| URL         | https://github.com/n0an/transcribe-cpp-swift/releases/download/0.2.1/TranscribeCpp.xcframework.zip |
| SHA-256     | `b348a496c1bdc17a9e6bb712696dc008b7110af28017611a15a5ed8d9a4b9737` |

The same checksum is the `checksum:` argument of the `.binaryTarget` in
`Package.swift`; SwiftPM refuses the download if they disagree. Recompute it
with either of:

```sh
swift package compute-checksum TranscribeCpp.xcframework.zip
shasum -a 256 TranscribeCpp.xcframework.zip
```

Note that the zip is not bit-for-bit reproducible: rebuilding from the same
commit produces a functionally identical framework, but timestamps and the
ad-hoc signature differ, so the checksum will not match. The checksum pins the
published asset, not the build inputs; the commit pin above is what fixes those.

## Verification performed on the published release

`swift build` and `swift test` were run from a scratch directory resolving this
package from its Git tag, so the xcframework came from the release URL above
rather than a local build. The suite is 54 tests; the model-gated ones skip
cleanly when no GGUF is present. To run those too:

```sh
curl -L -o /tmp/whisper-tiny-Q5_K_M.gguf \
  https://huggingface.co/handy-computer/whisper-tiny-gguf/resolve/main/whisper-tiny-Q5_K_M.gguf
TRANSCRIBE_SMOKE_MODEL=/tmp/whisper-tiny-Q5_K_M.gguf \
TRANSCRIBE_SMOKE_AUDIO=/path/to/transcribe.cpp/samples/jfk.wav \
  swift test
```

That path was exercised against this artifact: 42 tests run, 0 failures, with
the Metal backend initialising on-device.

## Updating to a newer upstream release

1. Check out the new upstream tag and re-run the build command above.
2. Re-copy `Sources/TranscribeCpp` and `Tests/TranscribeCppTests`, and re-copy
   `LICENSE` in case upstream's changed.
3. Package and checksum the new zip.
4. Cut a release on this repository whose tag matches the upstream version, and
   update the `url:` and `checksum:` in `Package.swift` together with the pins
   in this file.

Never move a tag that has already been pushed. SwiftPM records the commit it
first saw for a version in `~/.swiftpm/security/fingerprints/`, and on any later
resolve it hard-fails with `Revision <new> ... does not match previously
recorded value <old>`. The only recovery is deleting that machine's fingerprint
file. Corrections to a published version go out as a new version, never as a
retag.

Consumers should depend on an exact version. The binary target is pinned to one
release asset, so a floating range would silently swap the native library.
