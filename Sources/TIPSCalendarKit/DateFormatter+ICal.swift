import Foundation

extension DateFormatter {
	static let iCalDate: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd"
		formatter.timeZone = TimeZone(identifier: "UTC")
		return formatter
	}()

	static let iCalDateTime: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
		formatter.timeZone = TimeZone(identifier: "UTC")
		return formatter
	}()

	static let iso8601: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = TimeZone(identifier: "UTC")
		return formatter
	}()
}

public extension Date {
	func toICalDate() -> String {
		DateFormatter.iCalDate.string(from: self)
	}

	func toICalDateTime() -> String {
		DateFormatter.iCalDateTime.string(from: self)
	}
}

