// BlastkitExample.swift
// Example usage of the Blastkit package

import Blastkit
import Foundation

// This example demonstrates how to use the unified Blastkit package
// which provides access to all sub-modules through a single import

@main
struct BlastkitExample {
	static func main() async throws {
		print("🚀 Blastkit Example")
		print("===================")

		// Example 1: Using FetchKit for network requests
		await demonstrateFetchKit()

		// Example 2: Using TIPSKit for TIPS data
		await demonstrateTIPSKit()

		// Example 3: Using SwiftEase extensions
		demonstrateSwiftEase()

		// Example 4: Using TIPSCalendarKit
		demonstrateTIPSCalendarKit()

		print("\n✅ All examples completed successfully!")
	}

	// MARK: - FetchKit Example

	static func demonstrateFetchKit() async {
		print("\n📡 FetchKit Example:")

		let networkService = NetworkService()
		let endpoint = Endpoint(baseURL: "https://httpbin.org/json")

		do {
			let result = await networkService.request(endpoint: endpoint)
			switch result {
			case let .success(data):
				print("✅ Network request successful")
				if let jsonString = String(data: data, encoding: .utf8) {
					print("📄 Response: \(String(jsonString.prefix(100)))...")
				}
			case let .failure(error):
				print("❌ Network request failed: \(error)")
			}
		}
	}

	// MARK: - TIPSKit Example

	static func demonstrateTIPSKit() async {
		print("\n💰 TIPSKit Example:")

		// Create a TIPS request for summary data
		let request = TIPSRequest.summary(pageSize: 5)

		print("📊 TIPS Request created: \(request)")
		print("🔗 URL: \(request.urlRequest.url?.absoluteString ?? "N/A")")
	}

	// MARK: - SwiftEase Example

	static func demonstrateSwiftEase() {
		print("\n✨ SwiftEase Example:")

		// Boolean extensions
		let success = true
		let message = success.ifTrue { "Operation successful!" }.ifFalse { "Operation failed!" }
		print("✅ Boolean extension: \(message)")

		// Optional extensions
		let optionalValue: String? = nil
		let result = optionalValue.or("Default value")
		print("🔧 Optional extension: \(result)")

		// Castable example
		let stringValue = "42"
		if let intValue = stringValue.castable(as: Int.self) {
			print("🔄 Castable extension: \(stringValue) -> \(intValue)")
		}
	}

	// MARK: - TIPSCalendarKit Example

	static func demonstrateTIPSCalendarKit() {
		print("\n📅 TIPSCalendarKit Example:")

		// Create a TIPS account with holdings
		let holding = TIPSHolding(cusip: "912810RA8", quantity: 1000, purchaseDate: Date())
		let account = TIPSAccount(name: "Example Account", holdings: [holding])

		print("🏦 Account created: \(account.name)")
		print("📊 Holdings count: \(account.holdings.count)")
		print("🔢 CUSIPs: \(account.cusips)")
	}
}

// MARK: - Supporting Types

// Simple struct for demonstration
struct TIPSHolding {
	let cusip: String
	let quantity: Int
	let purchaseDate: Date
}

struct TIPSAccount {
	let name: String
	let holdings: [TIPSHolding]
	let id = UUID()

	var cusips: Set<String> {
		Set(holdings.map(\.cusip))
	}
}
