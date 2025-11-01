import Foundation
import TIPSKit

/// Loads TIPS ladder data from CSV files and creates TIPS accounts
public struct CSVLoader {
    
    /// Loads TIPS ladder data from CSV files and creates portfolio accounts
    /// - Returns: A tuple containing IRA and Roth TIPS accounts
    /// - Throws: CSV parsing errors or file reading errors
    public static func loadPortfolio() throws -> (iraAccount: TIPSAccount, rothAccount: TIPSAccount) {
        let iraHoldings = try loadHoldings(from: "IRALadder", purchaseDate: Date.from(year: 2025, month: 5, day: 13))
        let rothHoldings = try loadHoldings(from: "RothLadder", hasHeader: true, purchaseDate: Date.from(year: 2025, month: 4, day: 15))

        let iraAccount = TIPSAccount(name: "IRA Ladder", holdings: iraHoldings)
        let rothAccount = TIPSAccount(name: "Existing Roth TIPS Ladder", holdings: rothHoldings)

        return (iraAccount, rothAccount)
    }
    
    /// Loads a TIPS account from a CSV file path
    /// - Parameters:
    ///   - filePath: Path to the CSV file
    ///   - accountName: Name for the account (if nil, uses filename without extension)
    ///   - hasHeader: Whether the CSV file has a header row to skip
    ///   - purchaseDate: Purchase date for all holdings (used only for two-field format)
    /// - Returns: A TIPSAccount object
    /// - Throws: CSV parsing errors or file reading errors
    public static func loadAccount(from filePath: String, accountName: String? = nil, hasHeader: Bool = false, purchaseDate: Date? = nil) throws -> TIPSAccount {
        let url = URL(fileURLWithPath: filePath)
        let holdings = try loadHoldings(from: url, hasHeader: hasHeader, purchaseDate: purchaseDate)
        
        let name: String
        if let accountName = accountName {
            name = accountName
        } else {
            name = url.deletingPathExtension().lastPathComponent
        }
        
        return TIPSAccount(name: name, holdings: holdings)
    }
    
    /// Loads holdings from a CSV file path
    /// - Parameters:
    ///   - url: URL to the CSV file
    ///   - hasHeader: Whether the CSV file has a header row to skip
    ///   - purchaseDate: Purchase date for all holdings in this file (used only for two-field format)
    /// - Returns: Array of TIPSHolding objects
    private static func loadHoldings(from url: URL, hasHeader: Bool = false, purchaseDate: Date? = nil) throws -> [TIPSHolding] {
        let csvString = try String(contentsOf: url)
        var lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Skip header row if present
        if hasHeader && !lines.isEmpty {
            lines.removeFirst()
        }

        var holdings: [TIPSHolding] = []
        
        for line in lines {
            let components = line.components(separatedBy: ",")
            
            let cusip = components[0].trimmingCharacters(in: .whitespaces)
            guard let count = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
                throw CSVLoaderError.invalidCount(components[1])
            }
            
            let holding: TIPSHolding
            
            if components.count == 3 {
                // Three-field format: CUSIP, Count, PurchaseDate
                let dateString = components[2].trimmingCharacters(in: .whitespaces)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                guard let date = formatter.date(from: dateString) else {
                    throw CSVLoaderError.invalidDate(dateString)
                }
                holding = TIPSHolding(cusip: cusip, purchaseDate: date, count: count)
            } else if components.count == 2 && purchaseDate != nil {
                // Two-field format: CUSIP, Count (uses provided purchaseDate)
                holding = TIPSHolding(cusip: cusip, purchaseDate: purchaseDate!, count: count)
            } else {
                throw CSVLoaderError.invalidFormat(line)
            }
            
            holdings.append(holding)
        }
        
        return holdings
    }
    
    /// Loads holdings from a CSV file (bundle resource)
    /// - Parameters:
    ///   - filename: Name of the CSV file (without extension)
    ///   - hasHeader: Whether the CSV file has a header row to skip
    ///   - purchaseDate: Purchase date for all holdings in this file (used only for two-field format)
    /// - Returns: Array of TIPSHolding objects
    private static func loadHoldings(from filename: String, hasHeader: Bool = false, purchaseDate: Date? = nil) throws -> [TIPSHolding] {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "csv") else {
            throw CSVLoaderError.fileNotFound(filename)
        }
        return try loadHoldings(from: url, hasHeader: hasHeader, purchaseDate: purchaseDate)
    }
}

// MARK: - CSVLoaderError

public enum CSVLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case invalidCount(String)
    case invalidDate(String)
    case invalidFilePath(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "CSV file not found: \(filename).csv"
        case .invalidFormat(let line):
            return "Invalid CSV format in line: \(line)"
        case .invalidCount(let value):
            return "Invalid count value: \(value)"
        case .invalidDate(let value):
            return "Invalid date value: \(value)"
        case .invalidFilePath(let path):
            return "Invalid file path: \(path)"
        }
    }
}

// MARK: - Date Extension

private extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let calendar = Calendar.current
        return calendar.date(from: components) ?? Date()
    }
} 