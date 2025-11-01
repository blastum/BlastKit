//
//  PayoutCalculationDemo.swift
//  Blastkit
//
//  Created for demonstrating Step 5 payout calculation
//

import Foundation
import TIPSKit
import TIPSCalendarKit

@main
struct PayoutCalculationDemo {
    static func main() async {
        print("🔍 Finding CUSIP with ~5 years remaining...")

        // Load test accounts from CSV
        guard let (iraAccount, rothAccount) = try? CSVLoader.loadPortfolio() else {
            print("❌ Failed to load portfolio data")
            return
        }

        let service = TIPSService()
        service.addAccount(iraAccount)
        service.addAccount(rothAccount)

        // Get all unique CUSIPs
        let cusips = service.cusips()
        print("📊 Found \(cusips.count) unique CUSIPs across accounts")

        // Fetch summaries for all CUSIPs
        print("📡 Fetching summary data...")
        let summariesResult = await service.summaries()
        guard case let .success(summaries) = summariesResult else {
            print("❌ Failed to fetch summaries: \(summariesResult)")
            return
        }

        // For testing, use a specific CUSIP to verify calculations
        let testCUSIPs = ["91282CCM1"] // Focus on this Roth ladder CUSIP
        var finalCUSIP: String?
        var finalSummary: TIPSSummary?

        for cusip in testCUSIPs {
            if let summary = summaries[cusip] {
                finalCUSIP = cusip
                finalSummary = summary
                break
            }
        }

        if finalCUSIP == nil {
            print("❌ None of the test CUSIPs found, using first available")
            if let first = summaries.first {
                finalCUSIP = first.key
                finalSummary = first.value
            } else {
                print("❌ No CUSIPs available")
                return
            }
        }

        guard let finalCUSIP = finalCUSIP, let finalSummary = finalSummary else {
            print("❌ No CUSIP or summary data available")
            return
        }

        print("✅ Selected CUSIP: \(finalCUSIP)")
        if let maturity = finalSummary.maturityDate {
            print("📅 Maturity Date: \(DateFormatter.iso8601.string(from: maturity))")
        }
        if let rateRaw = finalSummary.interestRateRaw {
            print("📈 Interest Rate Raw: \(rateRaw)")
        }
        if let rate = finalSummary.interestRate {
            print("📈 Interest Rate: \(String(format: "%.3f", rate * 100))%")
        }

        // Create a test holding for this CUSIP - SINGLE BOND for verification
        let currentDate = Date()
        let testHolding = TIPSHolding(cusip: finalCUSIP, purchaseDate: currentDate, count: 1)
        let testAccount = TIPSAccount(name: "Demo Account", holdings: [testHolding])
        let demoService = TIPSService()
        demoService.addAccount(testAccount)

        // Generate payout schedule
        print("\n📅 Generating payout schedule...")
        let payoutSchedulesResult = demoService.payoutSchedules(summaries: summaries)
        guard case let .success(payoutSchedules) = payoutSchedulesResult else {
            print("❌ Failed to generate payout schedules: \(payoutSchedulesResult)")
            return
        }

        guard let payoutDates = payoutSchedules[finalCUSIP] else {
            print("❌ No payout dates found for CUSIP \(finalCUSIP)")
            return
        }

        print("📊 Found \(payoutDates.count) payout dates")

        // Fetch real index ratio data
        print("📡 Fetching real index ratio data...")
        let indexRatiosResult = await demoService.indexRatios(payoutSchedules: [finalCUSIP: payoutDates])
        let indexRatios: [String: [Date: TIPSDetail]]
        switch indexRatiosResult {
        case .success(let data):
            indexRatios = data
            print("📈 Found index ratio data for \(data.count) CUSIPs")
        case .failure(let error):
            print("⚠️ Failed to fetch index ratios: \(error)")
            print("🔄 Proceeding with empty index ratios (all payouts will be unadjusted)")
            indexRatios = [:]
        }

        let cusipIndexRatios = indexRatios[finalCUSIP] ?? [:]
        print("📈 Found \(cusipIndexRatios.count) index ratio records for \(finalCUSIP)")

        // Calculate payouts
        print("🧮 Calculating payouts...")
        let payouts = demoService.calculatePayouts(
            for: testHolding,
            account: testAccount,
            summary: finalSummary,
            payoutDates: payoutDates,
            indexRatios: cusipIndexRatios
        )

        // Display results with VERIFICATION
        print("\n🎯 PAYOUT CALCULATION VERIFICATION")
        print("==========================================")
        print("CUSIP: \(finalCUSIP)")
        print("Account: \(testAccount.name)")
        print("Holding: \(testHolding.count) bond")
        print("Face Value per Bond: $1000.00")
        if let rate = finalSummary.interestRate {
            print("Annual Interest Rate: \(String(format: "%.3f", rate * 100))% (\(String(format: "%.4f", rate)) decimal)")
            if cusipIndexRatios.isEmpty {
                print("No index ratio data available - using face value ($1000.00)")
                let semiAnnualInterest = 1000.0 * rate / 2.0
                print("Expected Semi-Annual Interest: $1000 × \(String(format: "%.4f", rate)) ÷ 2 = $\(String(format: "%.2f", semiAnnualInterest))")
                let maturityPayment = semiAnnualInterest + 1000.0
                print("Expected Maturity Payment: $\(String(format: "%.2f", semiAnnualInterest)) + $1000 = $\(String(format: "%.2f", maturityPayment))")
            } else {
                print("Index ratio data available - calculations will be inflation-adjusted")
                print("Found \(cusipIndexRatios.count) index ratio records")
            }
        }
        print("Total Payouts: \(payouts.count)")
        print("==========================================")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var totalAdjusted = 0.0
        var totalUnadjusted = 0.0
        var adjustedCount = 0
        var unadjustedCount = 0

        for (index, payout) in payouts.enumerated() {
            let statusIcon = payout.adjustmentStatus == TIPSPayout.AdjustmentStatus.adjusted ? "✅" : "⚠️*"
            let principalNote = payout.includesPrincipal ? " (MATURITY - includes $1000 principal)" : ""
            let indexRatioStr = payout.indexRatio.map { String(format: "%.4f", $0) } ?? "1.0000 (face value)"

            // Calculate detailed breakdown
            let indexRatio = payout.indexRatio ?? 1.0
            let adjustedPrincipal = 1000.0 * indexRatio
            let interestPayment = (adjustedPrincipal * payout.interestRate) / 2.0
            let totalPayoutPerBond = payout.includesPrincipal ? (interestPayment + adjustedPrincipal) : interestPayment

            print("\(index + 1). \(dateFormatter.string(from: payout.date)): $\(String(format: "%.2f", payout.amountPerBond))\(statusIcon)\(principalNote)")
            print("   Index Ratio: \(indexRatioStr)")
            print("   Adjusted Principal: $\(String(format: "%.2f", adjustedPrincipal))")
            print("   Interest Payment: $\(String(format: "%.2f", interestPayment)) (principal × rate ÷ 2)")
            print("   Calculated Total: $\(String(format: "%.2f", totalPayoutPerBond))")
            print("   Total: $\(String(format: "%.2f", payout.totalAmount))")

            if payout.adjustmentStatus == TIPSPayout.AdjustmentStatus.adjusted {
                totalAdjusted += payout.totalAmount
                adjustedCount += 1
            } else {
                totalUnadjusted += payout.totalAmount
                unadjustedCount += 1
            }
        }

        print("==========================================")
        print("VERIFICATION SUMMARY:")
        print("  Adjusted payouts: \(adjustedCount) ($\(String(format: "%.2f", totalAdjusted)))")
        print("  Unadjusted payouts: \(unadjustedCount) ($\(String(format: "%.2f", totalUnadjusted)))")
        print("  Total value: $\(String(format: "%.2f", totalAdjusted + totalUnadjusted))")
        print("==========================================")
        print("* Unadjusted payouts use face value ($1000) with no inflation adjustment")
        print("  All payouts shown are for a SINGLE bond - multiply by count for multiple bonds")

        // Now perform Step 6: Aggregate Payouts
        print("\n📊 STEP 6: AGGREGATING PAYOUTS")
        print("==========================================")
        
        // First, test with a simple 78-bond Roth holding for 91282CCM1
        print("\n🧪 TEST 1: Simple aggregation with 78 bonds of 91282CCM1")
        print("==========================================")
        let testHolding78 = TIPSHolding(cusip: finalCUSIP, purchaseDate: currentDate, count: 78)
        let testRothAccount = TIPSAccount(name: "Test Roth", holdings: [testHolding78])
        let testService78 = TIPSService()
        testService78.addAccount(testRothAccount)
        
        // Calculate payouts for 78 bonds
        let testPayouts78 = demoService.calculatePayouts(
            for: testHolding78,
            account: testRothAccount,
            summary: finalSummary,
            payoutDates: payoutDates,
            indexRatios: cusipIndexRatios
        )
        
        print("📊 Calculated \(testPayouts78.count) payouts for 78 bonds")
        
        // Show first payout detail
        if let firstPayout = testPayouts78.first {
            print("First payout: \(dateFormatter.string(from: firstPayout.date))")
            print("  Amount per bond: $\(String(format: "%.2f", firstPayout.amountPerBond))")
            print("  Count: \(firstPayout.count)")
            print("  Expected total: $\(String(format: "%.2f", firstPayout.amountPerBond)) × 78 = $\(String(format: "%.2f", firstPayout.amountPerBond * 78))")
            print("  Calculated total: $\(String(format: "%.2f", firstPayout.totalAmount))")
        }
        
        // Aggregate the 78-bond payouts
        let testCalendar = testService78.aggregatePayouts(testPayouts78)
        print("\n📅 Aggregated calendar:")
        print("  Dates: \(testCalendar.aggregatePayouts.count)")
        print("  Accounts: \(testCalendar.accountCalendars.count)")
        
        if let rothCalendar = testCalendar.accountCalendars.values.first {
            print("  Account: \(rothCalendar.accountName)")
            print("  Total adjusted: $\(String(format: "%.2f", rothCalendar.totalAdjustedAmount))")
            print("  Total unadjusted: $\(String(format: "%.2f", rothCalendar.totalUnadjustedAmount))")
            
            if let firstAgg = rothCalendar.payouts.first {
                print("\nFirst aggregated payout:")
                print("  Date: \(dateFormatter.string(from: firstAgg.date))")
                print("  Total amount: $\(String(format: "%.2f", firstAgg.totalAmount))")
                print("  Individual payouts: \(firstAgg.payoutCount)")
            }
        }

        // For a complete demo, we need to calculate payouts for the real accounts
        print("\n🔄 Switching to real portfolio data...")

        // Clear the demo service and add real accounts
        let realService = TIPSService()
        realService.addAccount(iraAccount)
        realService.addAccount(rothAccount)

        // Generate payout schedules for real accounts
        print("📅 Generating payout schedules for real accounts...")
        let realCusips = realService.cusips()
        print("📊 Real accounts have \(realCusips.count) CUSIPs: \(realCusips)")
        
        // Debug: Check holdings for 91282CCM1
        print("\n🔍 Debug: Holdings for 91282CCM1")
        for account in [iraAccount, rothAccount] {
            for holding in account.holdings where holding.cusip == "91282CCM1" {
                print("  \(account.name): \(holding.count) bonds")
            }
        }
        let realPayoutSchedulesResult = realService.payoutSchedules(summaries: summaries)
        guard case let .success(realPayoutSchedules) = realPayoutSchedulesResult else {
            print("❌ Failed to generate payout schedules for real accounts: \(realPayoutSchedulesResult)")
            return
        }
        print("📅 Generated payout schedules for \(realPayoutSchedules.count) CUSIPs")

        // Fetch index ratio data for all CUSIPs
        print("📡 Fetching index ratio data for all accounts...")
        let realIndexRatiosResult = await realService.indexRatios(payoutSchedules: realPayoutSchedules)
        let realIndexRatios: [String: [Date: TIPSDetail]]
        switch realIndexRatiosResult {
        case .success(let data):
            realIndexRatios = data
            print("📈 Found index ratio data for \(data.count) CUSIPs")
        case .failure(let error):
            print("⚠️ Failed to fetch index ratios: \(error)")
            print("🔄 Proceeding with empty index ratios (all payouts will be unadjusted)")
            realIndexRatios = [:]
        }

        // Calculate all payouts for real accounts
        print("🧮 Calculating all payouts across accounts...")
        let allPayouts = realService.calculateAllPayouts(
            summaries: summaries,
            payoutSchedules: realPayoutSchedules,
            indexRatios: realIndexRatios
        )

        print("📊 Found \(allPayouts.count) total payouts across all accounts")
        
        // Debug: Count payouts for 91282CCM1 and 91282CML2
        let ccm1Payouts = allPayouts.filter { $0.cusip == "91282CCM1" }
        let cml2Payouts = allPayouts.filter { $0.cusip == "91282CML2" }
        print("🔍 Debug: Found \(ccm1Payouts.count) payouts for 91282CCM1")
        if let first = ccm1Payouts.first {
            print("  Sample: \(DateFormatter.iso8601.string(from: first.date)), \(first.count) bonds, $\(String(format: "%.2f", first.totalAmount)) total")
        }
        print("🔍 Debug: Found \(cml2Payouts.count) payouts for 91282CML2")
        if let first = cml2Payouts.first, let ml2Summary = summaries["91282CML2"] {
            print("  Sample: \(DateFormatter.iso8601.string(from: first.date)), \(first.count) bonds, $\(String(format: "%.2f", first.totalAmount)) total")
            if let rate = ml2Summary.interestRate {
                print("  Interest rate: \(String(format: "%.3f", rate * 100))%")
                let perBond = first.totalAmount / Double(first.count)
                print("  Per bond: $\(String(format: "%.2f", perBond))")
                print("  Expected per bond: $\(String(format: "%.2f", 1000.0 * rate / 2.0))")
            }
        }

        // Aggregate payouts into calendar
        print("📅 Aggregating payouts into calendar...")
        let calendar = realService.aggregatePayouts(allPayouts)

        print("📈 Generated calendar with \(calendar.aggregatePayouts.count) payout dates")
        
        // Debug: Check aggregation for 2026-01-15
        if let testDateAgg = calendar.aggregatePayouts.first(where: { $0.date.description.contains("2026-01-15") }) {
            print("\n🔍 Debug: Aggregation for 2026-01-15")
            for accountPayout in testDateAgg.accountPayouts {
                print("  \(accountPayout.accountName): $\(String(format: "%.2f", accountPayout.totalAmount)), \(accountPayout.payoutCount) individual payouts")
                for (idx, payout) in accountPayout.payouts.enumerated() {
                    if idx < 3 || idx >= accountPayout.payouts.count - 1 {
                        print("    Payout \(idx): \(payout.cusip) × \(payout.count) bonds = $\(String(format: "%.2f", payout.totalAmount))")
                    } else if idx == 3 {
                        print("    ... \(accountPayout.payouts.count - 5) more payouts ...")
                    }
                }
            }
        }

        // Generate markdown table
        let markdownTable = generateMarkdownTable(calendar: calendar)

        // Output the table
        print("\n" + markdownTable)

        // Copy to clipboard using pbcopy
        print("\n📋 Copying markdown table to clipboard...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "echo '\(markdownTable)' | pbcopy"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                print("✅ Markdown table copied to clipboard successfully!")
            } else {
                print("❌ Failed to copy to clipboard")
            }
        } catch {
            print("❌ Error copying to clipboard: \(error)")
        }
    }

    static func generateMarkdownTable(calendar: PayoutCalendar) -> String {
        // Find IRA and Roth accounts
        guard let iraCalendar = calendar.accountCalendars.values.first(where: { $0.accountName.contains("IRA") }),
              let rothCalendar = calendar.accountCalendars.values.first(where: { $0.accountName.contains("Roth") }) else {
            return "Error: Could not find IRA and Roth accounts"
        }

        // Create date-to-account-payout mappings
        let iraPayoutsByDate = Dictionary(uniqueKeysWithValues: iraCalendar.payouts.map { ($0.date, $0) })
        let rothPayoutsByDate = Dictionary(uniqueKeysWithValues: rothCalendar.payouts.map { ($0.date, $0) })

        // Header
        var table = "| Date | IRA Account | Roth Account | Aggregate |\n"
        table += "|------|-------------|--------------|-----------|\n"

        // Date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        // Generate rows for each aggregate payout date with year totals
        var currentYear: String?
        var yearTotal = 0.0
        
        for (index, aggregatePayout) in calendar.aggregatePayouts.enumerated() {
            let dateStr = dateFormatter.string(from: aggregatePayout.date)
            let payoutYear = yearFormatter.string(from: aggregatePayout.date)

            // Check if any payouts on this date are unadjusted (missing TIPSDetail data)
            let hasUnadjustedPayouts = aggregatePayout.payouts.contains { $0.adjustmentStatus == .unadjusted }
            let asterisk = hasUnadjustedPayouts ? "*" : ""

            // IRA amount for this date
            let iraAmount = iraPayoutsByDate[aggregatePayout.date]?.totalAmount ?? 0.0
            let iraAmountStr = iraAmount > 0 ? String(format: "$%.2f", iraAmount) : "-"

            // Roth amount for this date
            let rothAmount = rothPayoutsByDate[aggregatePayout.date]?.totalAmount ?? 0.0
            let rothAmountStr = rothAmount > 0 ? String(format: "$%.2f", rothAmount) : "-"

            // Aggregate amount
            let aggregateAmountStr = String(format: "$%.2f", aggregatePayout.totalAmount)

            // Check if year changed
            if let prevYear = currentYear, prevYear != payoutYear {
                // Add year total row before the new year
                table += "| **Total payout for \(prevYear)** | | | **$\(String(format: "%.2f", yearTotal))** |\n"
                yearTotal = 0.0
            }
            
            currentYear = payoutYear
            yearTotal += aggregatePayout.totalAmount
            
            // Add row
            table += "|\(dateStr)\(asterisk) | \(iraAmountStr) | \(rothAmountStr) | \(aggregateAmountStr) |\n"
            
            // Add final year total if this is the last payout
            if index == calendar.aggregatePayouts.count - 1 {
                table += "| **Total payout for \(payoutYear)** | | | **$\(String(format: "%.2f", yearTotal))** |\n"
            }
        }

        // Add footer with totals
        table += "\n**Summary:**\n"
        table += "- **IRA Total Adjusted:** $\(String(format: "%.2f", iraCalendar.totalAdjustedAmount))\n"
        table += "- **IRA Total Unadjusted:** $\(String(format: "%.2f", iraCalendar.totalUnadjustedAmount))\n"
        table += "- **Roth Total Adjusted:** $\(String(format: "%.2f", rothCalendar.totalAdjustedAmount))\n"
        table += "- **Roth Total Unadjusted:** $\(String(format: "%.2f", rothCalendar.totalUnadjustedAmount))\n"
        table += "- **Aggregate Total Adjusted:** $\(String(format: "%.2f", calendar.totalAdjustedAmount))\n"
        table += "- **Aggregate Total Unadjusted:** $\(String(format: "%.2f", calendar.totalUnadjustedAmount))\n"
        table += "\n*Dates marked with * have payouts that are unadjusted (missing TIPSDetail data)*"

        return table
    }
}
