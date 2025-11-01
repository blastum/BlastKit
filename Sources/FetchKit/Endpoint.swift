//
//  Endpoint.swift
//  FetchKit
//
//  Created by James Blasius on 4/27/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 * A protocol that defines a type-safe, generic abstraction for HTTP API endpoints.
 *
 * The `Endpoint` protocol encapsulates all the details of a specific API endpoint,
 * including request construction and response parsing. It provides a clean separation
 * between network logic and business logic, making it easy to create, test, and maintain
 * API integrations.
 *
 * ## Overview
 *
 * Conforming types define:
 * - The expected output type (`Output`)
 * - The failure type (`Failure`)
 * - How to construct the HTTP request (`urlRequest`)
 * - How to parse the response (`decode`)
 *
 * ## Implementation Guidelines
 *
 * ### 1. Define Associated Types
 * - `Output`: The decoded response type (e.g., `User`, `[Product]`, `APIResponse<User>`)
 * - `Failure`: A domain-specific error type that conforms to `Error`
 *
 * ### 2. Implement urlRequest
 * - Construct the complete `URLRequest` with proper HTTP method, headers, and body
 * - Handle URL construction, query parameters, and authentication
 * - Set appropriate content type and accept headers
 *
 * ### 3. Implement decode
 * - Transform raw `Data` into your `Output` type
 * - Handle different response formats (JSON, XML, etc.)
 * - Provide meaningful error messages for parsing failures
 * - Use appropriate decoding strategies (e.g., date formats, key decoding)
 *
 * ## Example Usage
 *
 * ```swift
 * // Define your response types
 * struct User: Codable {
 *     let id: Int
 *     let name: String
 *     let email: String
 * }
 *
 * enum UserError: Error {
 *     case invalidResponse
 *     case parsingFailed(Error)
 * }
 *
 * // Implement the endpoint
 * enum UserEndpoint: Endpoint {
 *     case getUser(id: Int)
 *     case createUser(name: String, email: String)
 *
 *     // MARK: - Endpoint
 *
 *     public typealias Output = User
 *     public typealias Failure = UserError
 *
 *     public var urlRequest: URLRequest {
 *         switch self {
 *         case .getUser(let id):
 *             let url = URL(string: "https://api.example.com/users/\(id)")!
 *             var request = URLRequest(url: url)
 *             request.httpMethod = "GET"
 *             request.setValue("application/json", forHTTPHeaderField: "Accept")
 *             return request
 *
 *         case .createUser(let name, let email):
 *             let url = URL(string: "https://api.example.com/users")!
 *             var request = URLRequest(url: url)
 *             request.httpMethod = "POST"
 *             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
 *             
 *             let body = ["name": name, "email": email]
 *             request.httpBody = try? JSONSerialization.data(withJSONObject: body)
 *             return request
 *         }
 *     }
 *
 *     public func decode(_ result: Result<(Data, URLResponse), any Error>) -> Result<User, UserError> {
 *         result.flatMap { data, response in
 *             // Validate HTTP status code
 *             if let httpResponse = response as? HTTPURLResponse,
 *                !(200...299).contains(httpResponse.statusCode) {
 *                 return .failure(.invalidResponse)
 *             }
 *
 *             // Parse JSON response
 *             do {
 *                 let decoder = JSONDecoder()
 *                 let user = try decoder.decode(User.self, from: data)
 *                 return .success(user)
 *             } catch {
 *                 return .failure(.parsingFailed(error))
 *             }
 *         }
 *     }
 * }
 *
 * // Use with NetworkService
 * let networkService = NetworkService()
 * let endpoint = UserEndpoint.getUser(id: 123)
 *
 * Task {
 *     let result = await networkService.fetch(endpoint)
 *     switch result {
 *     case .success(let user):
 *         print("User: \(user.name)")
 *     case .failure(let error):
 *         print("Error: \(error)")
 *     }
 * }
 * ```
 *
 * ## Best Practices
 *
 * - **Error Handling**: Use domain-specific error types that provide meaningful information
 * - **Validation**: Validate HTTP status codes and response headers in the decode method
 * - **Configuration**: Make endpoints configurable through associated values or parameters
 * - **Reusability**: Create base endpoint types for common API patterns
 * - **Testing**: Use mock endpoints for unit testing network logic
 *
 * ## Integration with NetworkService
 *
 * The `NetworkService.fetch(_:)` method automatically:
 * 1. Executes the endpoint's `urlRequest`
 * 2. Passes the result to the endpoint's `decode` method
 * 3. Returns the decoded result or failure
 *
 * This separation allows you to focus on endpoint-specific logic while the network
 * service handles the common networking concerns.
 */
public protocol Endpoint {
    /// The type of the decoded response data.
    ///
    /// This should be the final type that consumers of your endpoint will work with.
    /// Common types include:
    /// - Simple models: `User`, `Product`
    /// - Collections: `[User]`, `Set<Product>`
    /// - Wrapper types: `APIResponse<User>`, `PaginatedResponse<Product>`
    associatedtype Output
    
    /// The type representing errors that can occur during endpoint execution.
    ///
    /// This should be a domain-specific error type that provides meaningful
    /// information about what went wrong. Common patterns include:
    /// - Enum-based errors with associated values
    /// - Custom error types that wrap underlying errors
    /// - Error types that conform to `LocalizedError` for user-facing messages
    associatedtype Failure: Error
    
    /// The HTTP request to be executed.
    ///
    /// This computed property should construct a complete `URLRequest` including:
    /// - Proper URL construction with query parameters
    /// - HTTP method (GET, POST, PUT, DELETE, etc.)
    /// - Required headers (Content-Type, Authorization, etc.)
    /// - Request body for POST/PUT requests
    /// - Any authentication tokens or API keys
    var urlRequest: URLRequest { get }
    
    /// Transforms the raw network response into the expected output type.
    ///
    /// This method is responsible for:
    /// - Parsing the raw `Data` into your `Output` type
    /// - Handling different response formats (JSON, XML, etc.)
    /// - Validating HTTP status codes and response headers
    /// - Converting parsing errors into your `Failure` type
    /// - Providing meaningful error messages for debugging
    ///
    /// ## Implementation Notes
    ///
    /// - Use `Result.flatMap` to chain operations and handle errors gracefully
    /// - Validate HTTP status codes before attempting to parse the response
    /// - Use appropriate `JSONDecoder` configurations for your API's format
    /// - Consider using custom decoding strategies for dates, numbers, etc.
    /// - Wrap underlying errors in your domain-specific error types
    ///
    /// ## Example Implementation
    ///
    /// ```swift
    /// public func decode(_ result: Result<(Data, URLResponse), any Error>) -> Result<User, UserError> {
    ///     result.flatMap { data, response in
    ///         // Validate HTTP status
    ///         guard let httpResponse = response as? HTTPURLResponse,
    ///               (200...299).contains(httpResponse.statusCode) else {
    ///             return .failure(.invalidResponse)
    ///         }
    ///
    ///         // Parse JSON
    ///         do {
    ///             let decoder = JSONDecoder()
    ///             decoder.dateDecodingStrategy = .iso8601
    ///             let user = try decoder.decode(User.self, from: data)
    ///             return .success(user)
    ///         } catch {
    ///             return .failure(.parsingFailed(error))
    ///         }
    ///     }
    /// }
    /// ```
    func decode(_ result: Result<(Data, URLResponse), any Error>) -> Result<Output, Failure>
}
