import Foundation

public enum CurrencyFormatter {
	static func format(_ amount: Double) -> String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.maximumFractionDigits = 2
		formatter.minimumFractionDigits = 2
		return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
	}
}

