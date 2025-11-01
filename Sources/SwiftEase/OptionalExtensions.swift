import Foundation

public extension Optional {
    
    /// Returns the wrapped value if present, otherwise evaluates and returns the autoclosure value
    ///
    /// This method provides a functional alternative to the nil-coalescing operator (`??`)
    /// that can be chained with other method calls.
    ///
    /// - Parameter value: An autoclosure that returns a default value of type `Wrapped`
    /// - Returns: The wrapped value if present, otherwise the result of the autoclosure
    ///
    /// ## Example:
    /// ```swift
    /// let name: String? = nil
    /// let displayName = name.or("Anonymous")
    /// // displayName is "Anonymous" (String, not String?)
    ///
    /// let score: Int? = 42
    /// let finalScore = score.or(0)
    /// // finalScore is 42 (Int, not Int?)
    /// ```
    func or(_ value: @autoclosure () -> Wrapped) -> Wrapped {
        switch self {
        case .some(let wrapped):
            wrapped
        case .none:
            value()
        }
    }
    
    /// Returns `true` if the optional contains a value, `false` otherwise
    ///
    /// This provides a more readable alternative to checking `optional != nil`.
    ///
    /// ## Example:
    /// ```swift
    /// let name: String? = "Alice"
    /// let emptyName: String? = nil
    ///
    /// print(name.isSet)      // true
    /// print(emptyName.isSet) // false
    /// ```
    var isSet: Bool {
        switch self {
        case .some:
            true
        case .none:
            false
        }
    }
    
    /// Returns `true` if the optional is `nil`, `false` otherwise
    ///
    /// This provides a more readable alternative to checking `optional == nil`.
    ///
    /// ## Example:
    /// ```swift
    /// let name: String? = "Alice"
    /// let emptyName: String? = nil
    ///
    /// print(name.isNil)      // false
    /// print(emptyName.isNil) // true
    /// ```
    var isNil: Bool {
        switch self {
        case .some:
            false
        case .none:
            true
        }
    }
} 