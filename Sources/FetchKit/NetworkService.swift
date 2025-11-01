//
//  NetworkService.swift
//  FetchKit
//
//  Created by James Blasius on 4/27/25.
//

import Foundation

// MARK: - NetworkServiceProtocol

/**
 * A protocol defining the contract for network operations using Endpoint types.
 *
 * This protocol abstracts network functionality, allowing for easy testing and
 * dependency injection. It provides a single method to fetch data from any
 * endpoint that conforms to the `Endpoint` protocol.
 *
 * ## Usage
 *
 * ```swift
 * let networkService: NetworkServiceProtocol = NetworkService()
 * let result = await networkService.fetch(userEndpoint)
 * ```
 */
public protocol NetworkServiceProtocol {
    /// Fetches data from the specified endpoint.
    ///
    /// - Parameter endpoint: The endpoint to fetch data from
    /// - Returns: A `Result` containing either the decoded output or a failure
    /// - Note: This method is asynchronous and should be called with `await`
    func fetch<E: Endpoint>(_ endpoint: E) async -> Result<E.Output, E.Failure>
}

// MARK: - NetworkService

/**
 * A concrete implementation of NetworkServiceProtocol that handles HTTP requests.
 *
 * NetworkService coordinates between URLSession and Endpoint types, executing
 * network requests and delegating response parsing to the endpoint's decode method.
 *
 * ## Key Features
 *
 * - **Automatic Coordination**: Handles the network request and response flow
 * - **Type Safety**: Leverages Swift's type system for compile-time safety
 * - **Error Handling**: Preserves endpoint-specific error types
 * - **Dependency Injection**: Accepts custom URLSession implementations for testing
 *
 * ## Example Usage
 *
 * ```swift
 * let networkService = NetworkService()
 * let userEndpoint = UserEndpoint.getUser(id: 123)
 *
 * Task {
 *     let result = await networkService.fetch(userEndpoint)
 *     switch result {
 *     case .success(let user):
 *         print("Fetched user: \(user.name)")
 *     case .failure(let error):
 *         print("Error: \(error)")
 *     }
 * }
 * ```
 */
public final class NetworkService: NetworkServiceProtocol {
    /// The URLSession instance used for network requests.
    ///
    /// Defaults to `URLSession.shared` but can be injected for testing
    /// or custom network configurations.
    private let session: URLSessionProtocol
    
    /// Unique identifier for this NetworkService instance (for tracking)
    public let instanceId: UUID
    
    /// Number of retry attempts for failed requests.
    /// Defaults to 2 (so 3 total attempts: initial + 2 retries).
    private let maxRetries: Int
    
    /// Delay in seconds between retries. Defaults to 1 second.
    private let retryDelay: TimeInterval
    
    /// Counter for network calls attempted (including retries)
    private var _callCount: Int = 0
    
    /// Counter for successful network calls
    private var _successCount: Int = 0
    
    /// Counter for failed network calls (after all retries)
    private var _failureCount: Int = 0
    
    /// Thread-safe access to call count
    private let callCountQueue = DispatchQueue(label: "NetworkService.callCount")
    
    /// Global counter across all NetworkService instances (for app-wide tracking)
    private static var _globalCallCount: Int = 0
    private static var _globalSuccessCount: Int = 0
    private static var _globalFailureCount: Int = 0
    private static let globalCallCountQueue = DispatchQueue(label: "NetworkService.globalCallCount")
    
    /// Global call count across all NetworkService instances in the app
    public static var globalCallCount: Int {
        globalCallCountQueue.sync { _globalCallCount }
    }
    
    /// Global success count across all NetworkService instances
    public static var globalSuccessCount: Int {
        globalCallCountQueue.sync { _globalSuccessCount }
    }
    
    /// Global failure count across all NetworkService instances
    public static var globalFailureCount: Int {
        globalCallCountQueue.sync { _globalFailureCount }
    }

    /// Total number of network calls attempted (including retries)
    public var callCount: Int {
        callCountQueue.sync { _callCount }
    }
    
    /// Number of successful network calls
    public var successCount: Int {
        callCountQueue.sync { _successCount }
    }
    
    /// Number of failed network calls (after all retries)
    public var failureCount: Int {
        callCountQueue.sync { _failureCount }
    }

    /// Creates a new NetworkService instance.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests.
    ///     Defaults to `URLSession.shared`.
    ///   - maxRetries: Number of retry attempts. Defaults to 2.
    ///   - retryDelay: Delay in seconds between retries. Defaults to 1.0.
    public init(session: URLSessionProtocol = URLSession.shared, maxRetries: Int = 2, retryDelay: TimeInterval = 1.0) {
        self.session = session
        self.instanceId = UUID()
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }

    /// Fetches data from the specified endpoint with automatic retry on network errors.
    ///
    /// This method:
    /// 1. Executes the endpoint's `urlRequest` using the configured session
    /// 2. Retries on transient network errors (connection lost, timeout, etc.)
    /// 3. Passes the raw result to the endpoint's `decode` method
    /// 4. Returns the decoded result or failure
    ///
    /// - Parameter endpoint: The endpoint to fetch data from
    /// - Returns: A `Result` containing either the decoded output or a failure
    public func fetch<E: Endpoint>(_ endpoint: E) async -> Result<E.Output, E.Failure> {
        var lastResult: Result<E.Output, E.Failure>?
        
        for attempt in 0...maxRetries {
            // Increment call count (including retries) - both instance and global
            callCountQueue.sync {
                _callCount += 1
            }
            Self.globalCallCountQueue.sync {
                Self._globalCallCount += 1
            }
            
            let rawResult = await session.data(for: endpoint.urlRequest)
            let decodedResult = endpoint.decode(rawResult)
            
            // If successful, return immediately
            if case .success = decodedResult {
                callCountQueue.sync {
                    _successCount += 1
                }
                Self.globalCallCountQueue.sync {
                    Self._globalSuccessCount += 1
                }
                return decodedResult
            }
            
            // Check if we should retry this error
            if attempt < maxRetries, shouldRetry(rawResult) {
                // Wait before retrying (exponential backoff: 1s, 2s, 4s...)
                let delay = retryDelay * pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                lastResult = decodedResult
                continue
            }
            
            // Not retryable or out of retries
            callCountQueue.sync {
                _failureCount += 1
            }
            Self.globalCallCountQueue.sync {
                Self._globalFailureCount += 1
            }
            return decodedResult
        }
        
        // Should never reach here, but return last result just in case
        callCountQueue.sync {
            _failureCount += 1
        }
        Self.globalCallCountQueue.sync {
            Self._globalFailureCount += 1
        }
        return lastResult!
    }
    
    /// Determines if a network error is retryable.
    ///
    /// Retries on transient network errors like:
    /// - Connection lost (-1005)
    /// - Timed out (-1001)
    /// - Network connection lost (-1005)
    /// - Cannot connect to host (-1004)
    /// - DNS lookup failed (-1006)
    ///
    /// - Parameter result: The raw result from URLSession
    /// - Returns: `true` if the error is retryable, `false` otherwise
    private func shouldRetry(_ result: Result<(Data, URLResponse), any Error>) -> Bool {
        guard case .failure(let error) = result else {
            return false
        }
        
        // Check if it's a URL error with a retryable code
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .cannotLoadFromNetwork,
                 .internationalRoamingOff,
                 .callIsActive,
                 .dataNotAllowed:
                return true
            default:
                return false
            }
        }
        
        // Also check for NSError with URL error domain
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            // Check specific error codes that are retryable
            let code = nsError.code
            switch code {
            case NSURLErrorTimedOut,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorDNSLookupFailed:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}
