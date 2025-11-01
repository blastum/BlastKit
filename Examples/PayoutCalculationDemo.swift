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

        // Find a CUSIP with maturity around 5 years from now (2029-2030)
        let currentDate = Date()
        let targetMaturityStart = Calendar.current.date(byAdding: .year, value: 4, to: currentDate)!
        let targetMaturityEnd = Calendar.current.date(byAdding: .year, value: 6, to: currentDate)!

        var selectedCUSIP: String?
        var selectedSummary: TIPSSummary?

        for (cusip, summary) in summaries {
            if let maturityDate = summary.maturityDate,
               maturityDate >= targetMaturityStart,
               maturityDate <= targetMaturityEnd {
                selectedCUSIP = cusip
                selectedSummary = summary
                break
            }
        }

        guard let cusip = selectedCUSIP, let summary = selectedSummary else {
            print("❌ No CUSIP found with maturity in target range (2029-2030)")
            // Fallback to any CUSIP with future maturity
            if let firstFuture = summaries.first(where: { $0.value.maturityDate?.isAfter(currentDate) ?? false }) {
                selectedCUSIP = firstFuture.key
                selectedSummary = firstFuture.value
                print("🔄 Using fallback CUSIP: \(firstFuture.key)")
            } else {
                print("❌ No CUSIPs with future maturity found")
                return
            }
        }

        guard let finalCUSIP = selectedCUSIP, let finalSummary = selectedSummary else {
            print("❌ No suitable CUSIP found")
            return
        }

        print("✅ Selected CUSIP: \(finalCUSIP)")
        if let maturity = finalSummary.maturityDate {
            print("📅 Maturity Date: \(DateFormatter.iso8601.string(from: maturity))")
        }
        if let rate = finalSummary.interestRate {
            print("📈 Interest Rate: \(String(format: "%.3f", rate * 100))%")
        }

        // Create a test holding for this CUSIP
        let testHolding = TIPSHolding(cusip: finalCUSIP, purchaseDate: currentDate, count: 10)
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

        // Fetch index ratio data
        print("📡 Fetching index ratio data...")
        let indexRatiosResult = await demoService.indexRatios(payoutSchedules: payoutSchedules)
        guard case let .success(indexRatios) = indexRatiosResult else {
            print("❌ Failed to fetch index ratios: \(indexRatiosResult)")
            return
        }

        let cusipIndexRatios = indexRatios[finalCUSIP] ?? [:]
        print("📈 Found \(cusipIndexRatios.count) index ratio records")

        // Calculate payouts
        print("🧮 Calculating payouts...")
        let payouts = demoService.calculatePayouts(
            for: testHolding,
            account: testAccount,
            summary: finalSummary,
            payoutDates: payoutDates,
            indexRatios: cusipIndexRatios
        )

        // Display results
        print("\n🎯 PAYOUT CALCULATION RESULTS")
        print("==========================================")
        print("CUSIP: \(finalCUSIP)")
        print("Account: \(testAccount.name)")
        print("Holding: \(testHolding.count) bonds")
        print("Total Payouts: \(payouts.count)")
        print("==========================================")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var totalAdjusted = 0.0
        var totalUnadjusted = 0.0
        var adjustedCount = 0
        var unadjustedCount = 0

        for payout in payouts {
            let statusIcon = payout.adjustmentStatus == .adjusted ? "✅" : "⚠️*"
            let principalNote = payout.includesPrincipal ? " (includes principal)" : ""
            let indexRatioStr = payout.indexRatio.map { String(format: "%.4f", $0) } ?? "N/A"

            print("\(dateFormatter.string(from: payout.date)): $\(String(format: "%.2f", payout.amountPerBond))\(statusIcon)\(principalNote)")
            print("  Index Ratio: \(indexRatioStr) | Total: $\(String(format: "%.2f", payout.totalAmount))")

            if payout.adjustmentStatus == .adjusted {
                totalAdjusted += payout.totalAmount
                adjustedCount += 1
            } else {
                totalUnadjusted += payout.totalAmount
                unadjustedCount += 1
            }
        }

        print("==========================================")
        print("SUMMARY:")
        print("  Adjusted payouts: \(adjustedCount) ($\(String(format: "%.2f", totalAdjusted)))")
        print("  Unadjusted payouts: \(unadjustedCount) ($\(String(format: "%.2f", totalUnadjusted)))")
        print("  Total value: $\(String(format: "%.2f", totalAdjusted + totalUnadjusted))")
        print("==========================================")
        print("* Unadjusted payouts use the last known index ratio")

        // Now perform Step 6: Aggregate Payouts
        print("\n📊 STEP 6: AGGREGATING PAYOUTS")
        print("==========================================")

        // For a complete demo, we need to calculate payouts for the real accounts
        print("🔄 Switching to real portfolio data...")

        // Clear the demo service and add real accounts
        let realService = TIPSService()
        realService.addAccount(iraAccount)
        realService.addAccount(rothAccount)

        // Calculate all payouts for real accounts
        print("🧮 Calculating all payouts across accounts...")
        let allPayouts = realService.calculateAllPayouts(
            summaries: summaries,
            payoutSchedules: payoutSchedules,
            indexRatios: indexRatios
        )

        print("📊 Found \(allPayouts.count) total payouts across all accounts")

        // Aggregate payouts into calendar
        print("📅 Aggregating payouts into calendar...")
        let calendar = realService.aggregatePayouts(allPayouts)

        print("📈 Generated calendar with \(calendar.aggregatePayouts.count) payout dates")

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

        // Generate rows for each aggregate payout date
        for aggregatePayout in calendar.aggregatePayouts {
            let dateStr = dateFormatter.string(from: aggregatePayout.date)

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

            // Add row
            table += "|\(dateStr)\(asterisk) | \(iraAmountStr) | \(rothAmountStr) | \(aggregateAmountStr) |\n"
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
