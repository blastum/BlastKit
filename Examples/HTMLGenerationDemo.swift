//
//  HTMLGenerationDemo.swift
//  Blastkit
//
//  Created for demonstrating HTML generation
//

import Foundation
import TIPSKit
import TIPSCalendarKit

@main
struct HTMLGenerationDemo {
	static func main() async {
		print("🔍 Loading portfolio and generating HTML calendar...")

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

		// Generate HTML
		print("🌐 Generating HTML...")
		let htmlGenerator = HTMLGenerator(title: "My TIPS Payout Calendar")
		let html = htmlGenerator.generate(from: calendar)

		// Save HTML to file
		let outputPath = "output.html"
		do {
			try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
			print("✅ HTML saved to \(outputPath)")
		} catch {
			print("❌ Failed to save HTML: \(error)")
		}
	}
}

