import Foundation

/// A protocol that enables safe type casting for conforming types
///
/// Types conforming to `Castable` can attempt to cast themselves to other types,
/// returning `nil` if the cast is not possible.
public protocol Castable {
    
    /// Attempts to cast the current instance to the specified type
    ///
    /// - Parameter type: The target type to cast to
    /// - Returns: The instance cast to the target type, or `nil` if casting fails
    ///
    /// ## Example:
    /// ```swift
    /// let number: Any = 42
    /// let intValue = number.cast(Int.self) // Returns 42
    /// let stringValue = number.cast(String.self) // Returns nil
    /// ```
    func cast<T>(_ type: T.Type) -> T?
}

// MARK: - Default Implementation

public extension Castable {
    
    /// Default implementation using Swift's conditional casting
    func cast<T>(_ type: T.Type) -> T? {
        self as? T
    }
}

// MARK: - Conformance for Common Types

extension NSObject: Castable {}

extension Array: Castable {}
extension Dictionary: Castable {}
extension Set: Castable {}
extension String: Castable {}

extension Int: Castable {}
extension Double: Castable {}
extension Float: Castable {}
extension Bool: Castable {}

extension Optional: Castable {
    public func cast<T>(_ type: T.Type) -> T? {
        switch self {
        case .some(let value):
            value as? T
        case .none:
            nil
        }
    }
}

 