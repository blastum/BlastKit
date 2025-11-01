//
//  TIPS_Payout_Dates_Demo.swift
//  Blastkit3
//
//  Demo showing payout date generation for TIPS securities using mock data
//

import TIPSKit
import SwiftEase
import Foundation

// Mock summary data for demo purposes
struct MockTIPSSummary {
    var cusip: String
    var datedDate: Date?
    var maturityDate: Date?
    var interestRate: Double?

    init(cusip: String, datedDate: Date? = nil, maturityDate: Date? = nil, interestRate: Double? = nil) {
        self.cusip = cusip
        self.datedDate = datedDate
        self.maturityDate = maturityDate
        self.interestRate = interestRate
    }
}

// Extend TIPSService to work with MockTIPSSummary for demo
extension TIPSService {
    func firstPaymentDate(for holding: TIPSHolding, summary: MockTIPSSummary) -> Date? {
        guard let datedDate = summary.datedDate else {
            return nil
        }

        let purchaseDate = holding.purchaseDate

        // If purchase date is before dated date → first payment is after dated date
        if purchaseDate.isBefore(datedDate) {
            return datedDate.nextSemiAnnualPaymentDate(from: datedDate)
        }

        // If purchase date is after dated date → first payment is next payment date after purchase
        return purchaseDate.nextSemiAnnualPaymentDate(from: datedDate)
    }

    func payoutDates(for holding: TIPSHolding, summary: MockTIPSSummary) throws -> [Date] {
        guard let maturityDate = summary.maturityDate else {
            throw Err.missingMaturityDate(cusip: holding.cusip)
        }

        guard let firstPaymentDate = firstPaymentDate(for: holding, summary: summary) else {
            throw Err.missingDatedDate(cusip: holding.cusip)
        }

        // Generate semi-annual payment dates from first payment to maturity
        let paymentDates = Date.semiAnnualPaymentDates(from: firstPaymentDate, to: maturityDate, referenceDate: summary.datedDate ?? firstPaymentDate)

        // Ensure maturity date is included if not already in the list
        if !paymentDates.contains(where: { $0.isSameDay(as: maturityDate) }) {
            return paymentDates + [maturityDate]
        }

        return paymentDates.sorted()
    }
}

// Create a demo service
let service = TIPSService()

// Create sample holdings with the acquisition date from the plan (2025-04-15)
let acquisitionDate = Date.from(year: 2025, month: 4, day: 15)!

// Sample holdings with different CUSIPs and realistic TIPS data
let holdings = [
    TIPSHolding(cusip: "912810FD5", purchaseDate: acquisitionDate, count: 100),
    TIPSHolding(cusip: "912810FH6", purchaseDate: acquisitionDate, count: 200),
    TIPSHolding(cusip: "912810FQ6", purchaseDate: acquisitionDate, count: 150)
]

// Create an account
let account = TIPSAccount(name: "Demo TIPS Portfolio", holdings: holdings)
service.addAccount(account)

// Mock summary data for demonstration (simulating real Treasury data)
let mockSummaries: [String: MockTIPSSummary] = [
    "912810FD5": MockTIPSSummary(
        cusip: "912810FD5",
        datedDate: Date.from(year: 2024, month: 4, day: 15), // April 15, 2024
        maturityDate: Date.from(year: 2029, month: 4, day: 15), // April 15, 2029
        interestRate: 0.0125 // 1.25%
    ),
    "912810FH6": MockTIPSSummary(
        cusip: "912810FH6",
        datedDate: Date.from(year: 2024, month: 1, day: 15), // January 15, 2024
        maturityDate: Date.from(year: 2031, month: 1, day: 15), // January 15, 2031
        interestRate: 0.0150 // 1.50%
    ),
    "912810FQ6": MockTIPSSummary(
        cusip: "912810FQ6",
        datedDate: Date.from(year: 2024, month: 10, day: 15), // October 15, 2024
        maturityDate: Date.from(year: 2029, month: 10, day: 15), // October 15, 2029
        interestRate: 0.0110 // 1.10%
    )
]

print("=== TIPS Payout Date Schedule Demo ===")
print("Acquisition Date: \(acquisitionDate.formatted(date: .abbreviated, time: .omitted))")
print("Holdings: \(holdings.map { "\($0.cusip): \($0.count) bonds" }.joined(separator: ", "))")
print()

// Get unique CUSIPs
let cusips = service.cusips()
print("Using mock data for \(cusips.count) unique CUSIPs...")
print()

// Generate payout schedules for each holding
for holding in holdings {
    guard let summary = mockSummaries[holding.cusip] else {
        print("❌ No summary data for \(holding.cusip)")
        continue
    }

    print("=== \(holding.cusip) ===")
    print("Count: \(holding.count) bonds")
    print("Purchase Date: \(holding.purchaseDate.formatted(date: .abbreviated, time: .omitted))")

    if let datedDate = summary.datedDate {
        print("Dated Date: \(datedDate.formatted(date: .abbreviated, time: .omitted))")
    } else {
        print("Dated Date: Not available")
    }

    if let maturityDate = summary.maturityDate {
        print("Maturity Date: \(maturityDate.formatted(date: .abbreviated, time: .omitted))")
    } else {
        print("Maturity Date: Not available")
        continue
    }

    if let interestRate = summary.interestRate {
        print("Interest Rate: \(String(format: "%.2f", interestRate * 100))%")
    }

    // Calculate first payment date
    let firstPayment = service.firstPaymentDate(for: holding, summary: summary)
    if let firstPayment = firstPayment {
        print("First Payment Date: \(firstPayment.formatted(date: .abbreviated, time: .omitted))")
    } else {
        print("First Payment Date: Could not determine")
        continue
    }

    // Generate all payout dates
    do {
        let payoutDates = try service.payoutDates(for: holding, summary: summary)

        print("All Payout Dates (\(payoutDates.count) total):")
        for (index, date) in payoutDates.enumerated() {
            let isMaturity = date.isSameDay(as: maturityDate!)
            let marker = isMaturity ? " (MATURITY)" : ""
            print("  \(index + 1). \(date.formatted(date: .abbreviated, time: .omitted))\(marker)")
        }

        print("Face Value per Bond: $1,000")
        print("Total Face Value: $\(holding.count * 1000)")
        print()

    } catch {
        print("❌ Error generating payout dates: \(error)")
        print()
    }
}

print("=== Demo Complete ===")
print()
print("Note: This demo uses mock data to illustrate the payout date calculation logic.")
print("In production, the actual Treasury API would be used to fetch real security data.")
