import Foundation

public extension Bool {
    
    /// Conditionally executes and returns the autoclosure value if the Bool is `true`
    ///
    /// This provides a functional approach to conditional execution, returning
    /// the value wrapped in an Optional. Returns `nil` if the Bool is `false`.
    ///
    /// - Parameter value: An autoclosure that returns a value of type `T`
    /// - Returns: The result of the autoclosure if `true`, otherwise `nil`
    ///
    /// ## Example:
    /// ```swift
    /// let isLoggedIn = true
    /// let welcomeMessage = isLoggedIn.if("Welcome back!")
    /// // welcomeMessage is "Welcome back!" (String?)
    ///
    /// let isGuest = false
    /// let guestMessage = isGuest.if("Hello guest!")
    /// // guestMessage is nil
    /// ```
    func `if`<T>(_ value: @autoclosure () -> T) -> T? {
        switch self {
        case true:
            value()
        case false:
            nil
        }
    }
    
    /// Conditionally executes one of two autoclosures based on the Bool value
    ///
    /// This provides a functional approach to if-else logic, always returning
    /// a value of type `T`. Executes the first autoclosure if `true`, 
    /// the second if `false`.
    ///
    /// - Parameters:
    ///   - trueValue: An autoclosure that returns a value when the Bool is `true`
    ///   - falseValue: An autoclosure that returns a value when the Bool is `false`
    /// - Returns: The result of the appropriate autoclosure
    ///
    /// ## Example:
    /// ```swift
    /// let hasPermission = true
    /// let access = hasPermission.if("Access granted", else: "Access denied")
    /// // access is "Access granted" (String)
    ///
    /// let isOnline = false
    /// let status = isOnline.if("Connected", else: "Offline")
    /// // status is "Offline" (String)
    /// ```
    func `if`<T>(_ trueValue: @autoclosure () -> T, else falseValue: @autoclosure () -> T) -> T {
        switch self {
        case true:
            trueValue()
        case false:
            falseValue()
        }
    }
} 