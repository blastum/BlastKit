# Blastkit Setup Guide

## Overview

This repository contains the **Blastkit** package, a unified Swift package that combines four powerful utility libraries:

- **FetchKit**: Network service and API client utilities
- **TIPSKit**: Treasury Inflation-Protected Securities (TIPS) data handling  
- **TIPSCalendarKit**: TIPS calendar and payout management
- **SwiftEase**: Swift language extensions and utilities

## Repository Structure

```
Blastkit/
├── Package.swift              # Main package configuration
├── README.md                  # Comprehensive documentation
├── LICENSE                    # MIT License
├── .gitignore                # Git ignore rules
├── Sources/                   # Source code
│   ├── Blastkit/             # Main module (re-exports all sub-modules)
│   ├── FetchKit/             # Network service utilities
│   ├── TIPSKit/              # TIPS data handling
│   ├── TIPSCalendarKit/      # TIPS calendar management
│   └── SwiftEase/            # Swift language extensions
├── Tests/                     # Test suites
│   ├── BlastkitTests/        # Main package tests
│   ├── FetchKitTests/        # FetchKit tests
│   ├── TIPSKitTests/         # TIPSKit tests
│   ├── TIPSCalendarKitTests/ # TIPSCalendarKit tests
│   └── SwiftEaseTests/       # SwiftEase tests
└── Examples/                  # Usage examples
    └── BlastkitExample.swift # Comprehensive example
```

## Getting Started

### Prerequisites

- Swift 5.9+
- iOS 13.0+ / macOS 13.0+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 15.0+ (recommended)

### Installation

#### Option 1: Swift Package Manager (Recommended)

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourusername/Blastkit.git`
3. Select the version you want to use
4. Click **Add Package**

#### Option 2: Package.swift

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Blastkit.git", from: "1.0.0")
]
```

### Usage

#### Import the entire package

```swift
import Blastkit

// All modules are available
let networkService = NetworkService()
let tipsRequest = TIPSRequest.summary()
let boolValue = true.ifTrue { "Yes" }
```

#### Import specific modules

```swift
import FetchKit
import TIPSKit
import TIPSCalendarKit
import SwiftEase

// Use specific module APIs
let endpoint = Endpoint(baseURL: "https://api.example.com")
let tipsResponse = TIPSResponse()
let account = TIPSAccount()
```

## Development

### Building

```bash
swift build
```

### Testing

```bash
# Run all tests
swift test

# Run specific test suites
swift test --filter BlastkitTests
swift test --filter FetchKitTests
swift test --filter TIPSKitTests
swift test --filter TIPSCalendarKitTests
swift test --filter SwiftEaseTests
```

### Running Examples

```bash
swift run BlastkitExample
```

## Module Dependencies

The package has the following dependency structure:

```
Blastkit
├── FetchKit (no dependencies)
├── TIPSKit (depends on FetchKit)
├── TIPSCalendarKit (depends on TIPSKit)
└── SwiftEase (no dependencies)
```

## Key Features

### FetchKit
- Network service abstraction
- URL session protocol conformance
- Endpoint management
- Mock URL session for testing

### TIPSKit
- TIPS request and response handling
- TIPS summary and detail models
- Date formatter extensions
- String extensions for TIPS data

### TIPSCalendarKit
- TIPS account management
- TIPS holdings tracking
- TIPS payout calculations
- Sequence extensions for TIPS data

### SwiftEase
- Boolean extensions
- Castable protocol utilities
- Optional extensions
- General Swift language enhancements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:

1. Check the existing issues
2. Create a new issue with a detailed description
3. Include your environment details (OS, Swift version, etc.)

## Migration from Individual Packages

If you were previously using the individual packages separately:

1. Remove the individual package dependencies
2. Add the Blastkit package dependency
3. Update your imports from individual modules to `import Blastkit`
4. Your existing code should work without changes

## Example Migration

**Before (individual packages):**
```swift
import FetchKit
import TIPSKit
import SwiftEase

let networkService = NetworkService()
let tipsRequest = TIPSRequest.summary()
let boolValue = true.ifTrue { "Yes" }
```

**After (Blastkit):**
```swift
import Blastkit

let networkService = NetworkService()
let tipsRequest = TIPSRequest.summary()
let boolValue = true.ifTrue { "Yes" }
```

The API remains exactly the same - only the import statement changes! 