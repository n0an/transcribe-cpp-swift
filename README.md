# transcribe-cpp-swift

A Swift package for [transcribe.cpp](https://github.com/handy-computer/transcribe.cpp),
providing on-device speech-to-text on macOS.

This is a packaging repository, not a fork with its own agenda. The Swift
sources are copied verbatim from upstream and the native library is built from a
pinned upstream commit, so the package exists purely to give a shipping app a
stable, self-hosted dependency instead of a moving revision. Provenance,
checksums and the exact build command are recorded in [`UPSTREAM.md`](UPSTREAM.md).

- Upstream: `handy-computer/transcribe.cpp` `v0.2.1`, MIT
- Platform: macOS 13+, universal `arm64 + x86_64` (Metal on Apple Silicon)
- Native code: prebuilt `TranscribeCpp.xcframework`, attached to this
  repository's releases and pinned by SHA-256

## Installation

```swift
.package(url: "https://github.com/n0an/transcribe-cpp-swift.git", exact: "0.2.1")
```

Then add the product to your target:

```swift
.product(name: "TranscribeCpp", package: "transcribe-cpp-swift")
```

Depend on an exact version. The binary target resolves to one specific release
asset, so a floating range would swap the native library underneath you.

## Usage

```swift
import TranscribeCpp

// One-shot.
let transcript = try Transcribe.transcribe(
    modelPath: "/path/to/model.gguf",
    pcm: pcm                       // 16 kHz mono Float32, range [-1, 1]
)
print(transcript.text)

// Reusing a loaded model, which is what you want for repeated calls.
let model = try Model(path: "/path/to/model.gguf")
let session = try model.session()
print(try session.run(pcm).text)
```

The API is upstream's, unchanged. See the
[upstream Swift binding README](https://github.com/handy-computer/transcribe.cpp/tree/v0.2.1/bindings/swift)
for the full surface: streaming, batching, backend selection, cancellation and
logging.

## Tests

```sh
swift test
```

The suite is 54 tests. The ones that need a GGUF model skip cleanly when none is
present; `UPSTREAM.md` shows how to fetch a small canary model and run them.

## License

MIT, and the notices travel with the code. transcribe.cpp is
copyright the transcribe.cpp authors; see [`LICENSE`](LICENSE). The xcframework
also links ggml and miniz, both MIT; see
[`THIRD-PARTY-LICENSES.md`](THIRD-PARTY-LICENSES.md). Those three license texts
are additionally bundled inside the xcframework itself.
