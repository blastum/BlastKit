import Foundation

public struct ICalEvent {
	public let uid: String
	public let dtStart: String
	public let dtEnd: String
	public let dtStamp: String
	public let summary: String
	public let description: String
	public let sequence: Int

	public init(
		uid: String,
		dtStart: String,
		dtEnd: String,
		dtStamp: String,
		summary: String,
		description: String,
		sequence: Int = 0
	) {
		self.uid = uid
		self.dtStart = dtStart
		self.dtEnd = dtEnd
		self.dtStamp = dtStamp
		self.summary = summary
		self.description = description
		self.sequence = sequence
	}

	public func render() -> String {
		var lines: [String] = []
		lines.append("")
		lines.append("BEGIN:VEVENT")
		lines.append("UID:\(uid)")
		lines.append("DTSTART;VALUE=DATE:\(dtStart)")
		lines.append("DTEND;VALUE=DATE:\(dtEnd)")
		lines.append("DTSTAMP:\(dtStamp)")
		lines.append("SUMMARY:\(escapeICal(summary))")
		lines.append(foldLine("DESCRIPTION:\(escapeICal(description))"))
		lines.append("SEQUENCE:\(sequence)")
		lines.append("END:VEVENT")
		return lines.joined(separator: "\r\n")
	}

	private func escapeICal(_ text: String) -> String {
		text
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: ";", with: "\\;")
			.replacingOccurrences(of: "\n", with: "\\n")
	}

	private func foldLine(_ line: String, maxLength: Int = 75) -> String {
		var result: [String] = []
		var remaining = line

		while remaining.count > maxLength {
			let endIndex = remaining.index(remaining.startIndex, offsetBy: maxLength)
			result.append(String(remaining[..<endIndex]))
			remaining = String(remaining[endIndex...])
		}

		if !remaining.isEmpty {
			result.append(remaining)
		}

		return result.joined(separator: "\r\n ")
	}
}

