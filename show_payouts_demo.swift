#!/usr/bin/env swift

// Simple demo to show Step 5 payout calculation results
// This demonstrates the key change: using last known index ratio for unadjusted payouts

import Foundation

// Mock data structures for demonstration
struct MockTIPSSummary {
    var cusip: String
    var datedDate: Date?
    var maturityDate: Date?
    var interestRate: Double?
}

struct MockTIPSDetail {
    var cusip: String
    var indexRatioDate: Date?
    var dailyIndexRatio: Double?
    var referenceCpi: Double?
}

struct MockTIPSHolding {
    var cusip: String
    var purchaseDate: Date
    var count: Int
}

struct MockTIPSAccount {
    var name: String
    var holdings: [MockTIPSHolding]
}

enum AdjustmentStatus {
    case adjusted      // Index ratio available and applied
    case unadjusted   // Index ratio not available, using last known value
}

struct MockTIPSPayout {
    var cusip: String
    var date: Date
    var accountName: String
    var amountPerBond: Double
    var count: Int
    var totalAmount: Double { amountPerBond * Double(count) }
    var adjustmentStatus: AdjustmentStatus
    var indexRatio: Double?
    var interestRate: Double
    var includesPrincipal: Bool
}

// Date extension for demo
extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    func formatted(date style: Date.FormatStyle.DateStyle = .abbreviated, time: Date.FormatStyle.TimeStyle = .omitted) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style == .abbreviated ? .medium : .short
        formatter.timeStyle = time == .omitted ? .none : .short
        return formatter.string(from: self)
    }
}

// Demo calculation logic (simplified version of the actual implementation)
func calculatePayouts(
    for holding: MockTIPSHolding,
    account: MockTIPSAccount,
    summary: MockTIPSSummary,
    payoutDates: [Date],
    indexRatios: [Date: MockTIPSDetail]
) -> [MockTIPSPayout] {
    guard let interestRate = summary.interestRate else {
        return []
    }

    let faceValue: Double = 1000.0 // Standard TIPS face value
    var lastKnownIndexRatio: Double? = nil
    var payouts: [MockTIPSPayout] = []

    for date in payoutDates {
        // Determine if this is the maturity date (includes principal)
        let isMaturityDate = summary.maturityDate?.isSameDay(as: date) ?? false

        // Get index ratio for this date, or use last known
        let tipsDetail = indexRatios[date]
        let indexRatio = tipsDetail?.dailyIndexRatio ?? lastKnownIndexRatio
        let adjustmentStatus: AdjustmentStatus = (tipsDetail != nil) ? .adjusted : .unadjusted

        // Update last known index ratio if we have one
        if let currentRatio = tipsDetail?.dailyIndexRatio {
            lastKnownIndexRatio = currentRatio
        }

        // Calculate adjusted principal
        let adjustedPrincipal = faceValue * (indexRatio ?? 1.0) // Use 1.0 (face value) if no index ratio ever available

        // Calculate interest payment (semi-annual)
        let interestPayment = (adjustedPrincipal * interestRate) / 2.0

        // Calculate total payout per bond
        let totalPayoutPerBond = isMaturityDate ?
            (interestPayment + adjustedPrincipal) : // Maturity: interest + principal
            interestPayment // Regular payment: interest only

        let payout = MockTIPSPayout(
            cusip: holding.cusip,
            date: date,
            accountName: account.name,
            amountPerBond: totalPayoutPerBond,
            count: holding.count,
            adjustmentStatus: adjustmentStatus,
            indexRatio: indexRatio,
            interestRate: interestRate,
            includesPrincipal: isMaturityDate
        )

        payouts.append(payout)
    }

    return payouts
}

// Main demo
func main() {
    print("=== Step 5: Payout Calculation Demo ===")
    print("Demonstrating the key change: using last known index ratio for unadjusted payouts")
    print()

    // Create a sample holding with ~5 years remaining (maturity 2029)
    let holding = MockTIPSHolding(
        cusip: "912810FD5",
        purchaseDate: Date.from(year: 2024, month: 1, day: 1)!,
        count: 100
    )
    let account = MockTIPSAccount(name: "Demo Account", holdings: [holding])

    // Mock summary for a bond maturing in ~5 years (2029)
    let summary = MockTIPSSummary(
        cusip: "912810FD5",
        datedDate: Date.from(year: 2024, month: 4, day: 15),
        maturityDate: Date.from(year: 2029, month: 4, day: 15), // ~5 years from 2024
        interestRate: 0.01375 // 1.375%
    )

    print("Sample CUSIP: \(summary.cusip)")
    print("Maturity Date: \(summary.maturityDate?.formatted() ?? "Unknown")")
    print("Interest Rate: \(String(format: "%.3f", (summary.interestRate ?? 0) * 100))%")
    print("Holding: \(holding.count) bonds")
    print()

    // Generate payout dates (would normally be from step 3)
    let payoutDates = [
        Date.from(year: 2024, month: 10, day: 15)!, // Past - has data
        Date.from(year: 2025, month: 4, day: 15)!,  // Past - has data
        Date.from(year: 2025, month: 10, day: 15)!, // Future - no data yet
        Date.from(year: 2026, month: 4, day: 15)!,  // Future - no data yet
        Date.from(year: 2026, month: 10, day: 15)!, // Future - no data yet
        Date.from(year: 2027, month: 4, day: 15)!,  // Future - no data yet
        Date.from(year: 2027, month: 10, day: 15)!, // Future - no data yet
        Date.from(year: 2028, month: 4, day: 15)!,  // Future - no data yet
        Date.from(year: 2028, month: 10, day: 15)!, // Future - no data yet
        Date.from(year: 2029, month: 4, day: 15)!   // Maturity - no data yet
    ]

    print("Generated \(payoutDates.count) payout dates:")
    for (index, date) in payoutDates.enumerated() {
        let isMaturity = index == payoutDates.count - 1
        let marker = isMaturity ? " (MATURITY)" : ""
        print("  \(index + 1). \(date.formatted())\(marker)")
    }
    print()

    // Simulate index ratio data: only first 2 dates have data
    var indexRatios: [Date: MockTIPSDetail] = [:]

    // Past dates with known index ratios
    indexRatios[payoutDates[0]] = MockTIPSDetail(
        cusip: "912810FD5",
        indexRatioDate: payoutDates[0],
        dailyIndexRatio: 1.052,
        referenceCpi: 250.0
    )
    indexRatios[payoutDates[1]] = MockTIPSDetail(
        cusip: "912810FD5",
        indexRatioDate: payoutDates[1],
        dailyIndexRatio: 1.068,
        referenceCpi: 252.5
    )

    print("Index Ratio Data Available:")
    print("  \(payoutDates[0].formatted()): \(indexRatios[payoutDates[0]]!.dailyIndexRatio!)")
    print("  \(payoutDates[1].formatted()): \(indexRatios[payoutDates[1]]!.dailyIndexRatio!)")
    print("  Future dates: No data available yet")
    print()

    // Calculate payouts
    let payouts = calculatePayouts(
        for: holding,
        account: account,
        summary: summary,
        payoutDates: payoutDates,
        indexRatios: indexRatios
    )

    print("🎯 PAYOUT CALCULATION RESULTS:")
    print("==========================================")

    var totalAdjustedAmount = 0.0
    var totalUnadjustedAmount = 0.0
    var adjustedCount = 0
    var unadjustedCount = 0

    for payout in payouts {
        let statusIcon = payout.adjustmentStatus == .adjusted ? "✅" : "⚠️*"
        let principalNote = payout.includesPrincipal ? " (includes principal)" : ""
        let indexRatioStr = payout.indexRatio.map { String(format: "%.4f", $0) } ?? "N/A"

        print("\(payout.date.formatted()): $\(String(format: "%.2f", payout.amountPerBond))\(statusIcon)\(principalNote)")
        print("  Index Ratio: \(indexRatioStr) | Total: $\(String(format: "%.2f", payout.totalAmount))")

        if payout.adjustmentStatus == .adjusted {
            totalAdjustedAmount += payout.totalAmount
            adjustedCount += 1
        } else {
            totalUnadjustedAmount += payout.totalAmount
            unadjustedCount += 1
        }
    }

    print("==========================================")
    print("SUMMARY:")
    print("  Adjusted payouts: \(adjustedCount) ($\(String(format: "%.2f", totalAdjustedAmount)))")
    print("  Unadjusted payouts: \(unadjustedCount) ($\(String(format: "%.2f", totalUnadjustedAmount)))")
    print("  Total projected value: $\(String(format: "%.2f", totalAdjustedAmount + totalUnadjustedAmount)))")
    print("==========================================")
    print()
    print("📝 KEY CHANGE: Unadjusted payouts use the LAST KNOWN index ratio (\(String(format: "%.4f", 1.068)))")
    print("   instead of dropping back to face value (1.0000)")
    print("   This provides a more realistic projection for future payouts")
    print("   * = Subject to change when new index ratio data becomes available")
    print()
    print("=== Demo Complete ===")
}

// Helper extension
extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

main()
