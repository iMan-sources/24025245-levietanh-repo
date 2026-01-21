# Thesis CLI

Swift CLI application for thesis project.

## Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+ (optional, for development)

## Building

Build the project using Swift Package Manager:

```bash
cd src
swift build
```

## Running

Run the CLI tool:

```bash
swift run ThesisCLI
```

Or run with arguments:

```bash
swift run ThesisCLI --help
swift run ThesisCLI argument1 argument2
```

## Testing

Run the test suite:

```bash
swift test
```

## Development

### Project Structure

```
src/
├── Package.swift           # Swift Package Manager manifest
├── Sources/
│   └── main.swift         # Main entry point
└── Tests/
    └── ThesisCLITests.swift  # Unit tests
```

### Adding Dependencies

To add a dependency, edit `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
],
```

Then add it to your target:

```swift
.executableTarget(
    name: "ThesisCLI",
    dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    path: "Sources"
),
```

## Building for Release

Build an optimized release version:

```bash
swift build -c release
```

The executable will be located at:
```
.build/release/ThesisCLI
```

## Installation

You can copy the release binary to a location in your PATH:

```bash
swift build -c release
cp .build/release/ThesisCLI /usr/local/bin/
```

## License

[Add your license here]
