# Blastkit

A comprehensive Swift package that combines multiple utility libraries into a single, cohesive toolkit for iOS, macOS, tvOS, and watchOS development.

## Overview

Blastkit provides a unified interface to four powerful Swift libraries:

- **FetchKit**: Network service and API client utilities
- **TIPSKit**: Treasury Inflation-Protected Securities (TIPS) data handling
- **TIPSCalendarKit**: TIPS calendar and payout management
- **SwiftEase**: Swift language extensions and utilities

## Features

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

## Requirements

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add Blastkit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Blastkit.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version you want to use

## Usage

### Import the entire package

```swift
import Blastkit

// All modules are available
let networkService = NetworkService()
let tipsRequest = TIPSRequest()
let boolValue = true.ifTrue { "Yes" }
```

### Import specific modules

```swift
import FetchKit
import TIPSKit
import TIPSCalendarKit
import SwiftEase

// Use specific module APIs
let endpoint = Endpoint(baseURL: "https://api.example.com")
let tipsResponse = TIPSResponse()
let account = TIPSAccount()
let castable = Castable()
```

## Examples

### Network Service with FetchKit

```swift
import FetchKit

let networkService = NetworkService()
let endpoint = Endpoint(baseURL: "https://api.example.com")

// Make network requests
networkService.request(endpoint: endpoint) { result in
    switch result {
    case .success(let data):
        print("Success: \(data)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### TIPS Data Handling

```swift
import TIPSKit

let request = TIPSRequest()
let response = TIPSResponse()
let summary = TIPSSummary()

// Process TIPS data
if let tipsData = response.data {
    // Handle TIPS information
}
```

### Swift Extensions

```swift
import SwiftEase

// Boolean extensions
let message = true.ifTrue { "Success" }.ifFalse { "Failure" }

// Optional extensions
let value: String? = "Hello"
let result = value.or("Default")

// Castable utilities
let castable = Castable()
```

## Testing

Run the test suite:

```bash
swift test
```

Or run specific test targets:

```bash
swift test --filter BlastkitTests
swift test --filter FetchKitTests
swift test --filter TIPSKitTests
swift test --filter TIPSCalendarKitTests
swift test --filter SwiftEaseTests
```

## Project Structure

```
Blastkit/
├── Package.swift
├── README.md
├── Sources/
│   ├── Blastkit/
│   │   └── Blastkit.swift
│   ├── FetchKit/
│   │   ├── Endpoint.swift
│   │   ├── NetworkService.swift
│   │   └── URLSessionProtocol.swift
│   ├── TIPSKit/
│   │   ├── DateFormatterExtensions.swift
│   │   ├── StringExtensions.swift
│   │   ├── TIPSDetail.swift
│   │   ├── TIPSRequest.swift
│   │   ├── TIPSResponse.swift
│   │   └── TIPSSummary.swift
│   ├── TIPSCalendarKit/
│   │   ├── SequenceExtensions.swift
│   │   ├── TIPSAccount.swift
│   │   ├── TIPSHolding.swift
│   │   ├── TIPSPayout.swift
│   │   └── TIPSService.swift
│   └── SwiftEase/
│       ├── BoolExtensions.swift
│       ├── Castable.swift
│       ├── OptionalExtensions.swift
│       └── SwiftEase.swift
└── Tests/
    ├── BlastkitTests/
    ├── FetchKitTests/
    ├── TIPSKitTests/
    ├── TIPSCalendarKitTests/
    └── SwiftEaseTests/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the existing issues
2. Create a new issue with a detailed description
3. Include your environment details (OS, Swift version, etc.)

## Acknowledgments

Blastkit combines the best practices and utilities from multiple Swift packages, providing developers with a comprehensive toolkit for building robust iOS, macOS, tvOS, and watchOS applications. 