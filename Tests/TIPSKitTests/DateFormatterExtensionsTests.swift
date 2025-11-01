//
//  DateFormatterExtensionsTests.swift
//  TIPSKitTests
//
//  Created by James Blasius on 8/17/25.
//

import Testing
import Foundation
@testable import TIPSKit

@Suite
struct DateFormatterExtensionsTests {
    
    @Test func testISO8601DateFormatter() throws {
        let formatter = DateFormatter.iso8601
        
        // Should be able to parse ISO8601 dates
        let testDateString = "2025-08-17T19:30:00Z"
        let parsedDate = formatter.date(from: testDateString)
        
        #expect(parsedDate != nil)
        
        if let date = parsedDate {
            // Should be able to format back to string
            let formattedString = formatter.string(from: date)
            #expect(formattedString == testDateString)
        }
    }
    
    @Test func testISO8601DateFormatterWithDifferentFormats() throws {
        let formatter = DateFormatter.iso8601
        
        // Test various ISO8601 formats
        let testCases = [
            "2025-08-17T19:30:00Z",           // Basic format
            "2025-08-17T19:30:00+00:00",      // With timezone offset
            "2025-08-17T19:30:00-05:00"       // With negative timezone offset
        ]
        
        for dateString in testCases {
            let parsedDate = formatter.date(from: dateString)
            #expect(parsedDate != nil, "Failed to parse: \(dateString)")
        }
    }
    
    @Test func testISO8601DateFormatterInvalidDates() throws {
        let formatter = DateFormatter.iso8601
        
        // Test invalid date strings
        let invalidDates = [
            "2025-13-17T19:30:00Z",           // Invalid month
            "2025-08-32T19:30:00Z",           // Invalid day
            "2025-08-17T25:30:00Z",           // Invalid hour
            "not-a-date",                      // Completely invalid
            "2025-08-17"                      // Missing time component
        ]
        
        for invalidDate in invalidDates {
            let parsedDate = formatter.date(from: invalidDate)
            #expect(parsedDate == nil, "Should not parse invalid date: \(invalidDate)")
        }
    }
} 