import Foundation

public struct ICalCalendar {
	public let events: [ICalEvent]
	public let prodId: String
	public let version: String = "2.0"
	public let calScale: String = "GREGORIAN"
	public let method: String = "PUBLISH"

	public init(
		events: [ICalEvent],
		prodId: String = "-//TIPS Calendar Kit//TIPS Payout Calendar//EN"
	) {
		self.events = events
		self.prodId = prodId
	}

	public func render() -> String {
		var lines: [String] = []
		lines.append("BEGIN:VCALENDAR")
		lines.append("VERSION:\(version)")
		lines.append("PRODID:\(prodId)")
		lines.append("CALSCALE:\(calScale)")
		lines.append("METHOD:\(method)")

		for event in events {
			lines.append(event.render())
		}

  		lines.append("")
		lines.append("END:VCALENDAR")
		return lines.joined(separator: "\r\n")
	}
}

