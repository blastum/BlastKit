//
//  AggregatePayoutsDemo.swift
//  Blastkit
//
//  Created for demonstrating Step 6 payout aggregation
//

import Foundation
import TIPSKit
import TIPSCalendarKit

@main
struct AggregatePayoutsDemo {
    static func main() async {
        print("🔍 Loading portfolio and calculating aggregate payouts...")

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

        // Generate payout schedules
        print("📅 Generating payout schedules...")
        let payoutSchedulesResult = service.payoutSchedules(summaries: summaries)
        guard case let .success(payoutSchedules) = payoutSchedulesResult else {
            print("❌ Failed to generate payout schedules: \(payoutSchedulesResult)")
            return
        }

        // Fetch index ratio data
        print("📡 Fetching index ratio data...")
        let indexRatiosResult = await service.indexRatios(payoutSchedules: payoutSchedules)
        guard case let .success(indexRatios) = indexRatiosResult else {
            print("❌ Failed to fetch index ratios: \(indexRatiosResult)")
            return
        }

        // Calculate all payouts
        print("🧮 Calculating payouts...")
        let allPayouts = service.calculateAllPayouts(
            summaries: summaries,
            payoutSchedules: payoutSchedules,
            indexRatios: indexRatios
        )

        print("📊 Found \(allPayouts.count) total payouts across all accounts")

        // Aggregate payouts into calendar
        print("📅 Aggregating payouts into calendar...")
        let calendar = service.aggregatePayouts(allPayouts)

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
