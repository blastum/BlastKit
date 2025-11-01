import Foundation

/// SwiftEase: A collection of convenient Swift extensions to make life easier
///
/// This library provides various extensions and utilities to streamline common
/// development tasks and improve productivity.
public struct SwiftEase {
    
    /// Library version
    public static let version = "1.0.0"
    
    private init() {
        // Prevent instantiation - this is a namespace
    }
}

// MARK: - Sequence Extensions

extension Sequence where Element: Hashable {
    public func toSet() -> Set<Element> {
        Set(self)
    }

    public func toArray() -> [Element] {
        Array(self)
    }
}

// MARK: - DateFormatter Extensions

public extension DateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
}

// MARK: - String Extensions

extension String {
    public var date: Date? {
        // Try ISO8601 first
        if let date = DateFormatter.iso8601.date(from: self) {
            return date
        }

        // Try YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Try MM/dd/yyyy format
        dateFormatter.dateFormat = "MM/dd/yyyy"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        return nil
    }

    public var double: Double? {
        Double(self)
    }

    public var int: Int? {
        Int(self)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Create a date from year, month, day components
    public static func from(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }
    /// Add months to a date
    public func adding(months: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Get the day of month for this date
    public var day: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }

    /// Get the month for this date
    public var month: Int {
        let calendar = Calendar.current
        return calendar.component(.month, from: self)
    }

    /// Get the year for this date
    public var year: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }

    /// Check if this date is before another date
    public func isBefore(_ other: Date) -> Bool {
        self < other
    }

    /// Check if this date is after another date
    public func isAfter(_ other: Date) -> Bool {
        self > other
    }

    /// Check if this date is the same day as another date
    public func isSameDay(as other: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: other)
    }

    /// Create a new date with the same day/month but different year
    public func with(year: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.year = year
        return calendar.date(from: components)
    }

    /// Create a new date with the same year/month but different day
    public func with(day: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.day = day
        return calendar.date(from: components)
    }
}

// MARK: - TIPS Payment Date Calculations

extension Date {
    /// Calculate the next semi-annual payment date after this date
    /// TIPS payments are typically made on the 15th of the month (January 15, July 15)
    /// - Parameter referenceDate: The dated date or reference date for payment schedule
    /// - Returns: The next payment date after this date (strictly after, not including same day)
    public func nextSemiAnnualPaymentDate(from referenceDate: Date) -> Date? {
        let calendar = Calendar.current

        // Get the month and day from the reference date
        let referenceMonth = calendar.component(.month, from: referenceDate)
        let referenceDay = calendar.component(.day, from: referenceDate)

        // Determine the two payment months (typically 6 months apart)
        // For TIPS, payments are usually January 15 and July 15, or April 15 and October 15, etc.
        // We'll use the reference month as the starting point
        var paymentMonths = [referenceMonth, (referenceMonth + 6) % 12]
        if paymentMonths[1] == 0 { paymentMonths[1] = 12 } // Handle December wrap-around
        let paymentDay = referenceDay

        // Find the next payment date strictly after this date
        var currentYear = calendar.component(.year, from: self)

        // Check both payment months in the current year
        for paymentMonth in paymentMonths.sorted() {
            var components = DateComponents()
            components.year = currentYear
            components.month = paymentMonth
            components.day = paymentDay

            if let paymentDate = calendar.date(from: components),
               paymentDate.isAfter(self) {
                return paymentDate
            }
        }

        // If no payment date found this year, check next year
        currentYear += 1
        for paymentMonth in paymentMonths.sorted() {
            var components = DateComponents()
            components.year = currentYear
            components.month = paymentMonth
            components.day = paymentDay

            if let paymentDate = calendar.date(from: components) {
                return paymentDate
            }
        }

        return nil
    }

    /// Generate all semi-annual payment dates from start date to end date (inclusive)
    /// Assumes that the 'from' date is already a valid payment date and should be included
    /// - Parameters:
    ///   - from: Start date for payment schedule (should be a payment date)
    ///   - to: End date for payment schedule
    ///   - referenceDate: Reference date for determining payment schedule pattern
    /// - Returns: Array of payment dates
    public static func semiAnnualPaymentDates(from start: Date, to end: Date, referenceDate: Date) -> [Date] {
        guard start.isBefore(end) || start.isSameDay(as: end) else { return [] }

        var dates: [Date] = []
        var currentDate = start

        // Include the start date (assumed to be a payment date)
        dates.append(start)
        currentDate = currentDate.adding(months: 6)

        // Generate subsequent dates
        while currentDate.isBefore(end) || currentDate.isSameDay(as: end) {
            dates.append(currentDate)
            currentDate = currentDate.adding(months: 6)
        }

        return dates
    }
} 