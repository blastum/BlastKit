import Foundation
import TIPSKit

public class CalendarGenerator {
	public let uidDomain: String

	public init(uidDomain: String = "tipscalendarkit.github.io") {
		self.uidDomain = uidDomain
	}

	public func generate(
		from payoutCalendar: PayoutCalendar,
		generatedAt: Date = Date()
	) -> ICalCalendar {
		let events = payoutCalendar.aggregatePayouts.map { aggregatePayout in
			formatEvent(from: aggregatePayout, generatedAt: generatedAt)
		}

		return ICalCalendar(events: events)
	}

	private func formatEvent(
		from aggregatePayout: AggregatePayout,
		generatedAt: Date
	) -> ICalEvent {
		let dateString = aggregatePayout.date.toICalDate()
		let uid = generateUID(for: aggregatePayout.date)
		let dtStart = dateString
		let dtEnd = aggregatePayout.date.addingTimeInterval(86400).toICalDate()
		let dtStamp = generatedAt.toICalDateTime()
		let summary = formatSummary(from: aggregatePayout)
		let description = formatDescription(from: aggregatePayout)

		return ICalEvent(
			uid: uid,
			dtStart: dtStart,
			dtEnd: dtEnd,
			dtStamp: dtStamp,
			summary: summary,
			description: description
		)
	}

	private func generateUID(for date: Date) -> String {
		let dateString = date.toICalDate()
		return "\(dateString)@\(uidDomain)"
	}

	private func formatSummary(from aggregatePayout: AggregatePayout) -> String {
		let formattedAmount = CurrencyFormatter.format(aggregatePayout.totalAmount)
		let hasUnadjusted = aggregatePayout.unadjustedAmount > 0
		let asterisk = hasUnadjusted ? "*" : ""
		return "TIPS: \(formattedAmount)\(asterisk)"
	}

	private func formatDescription(from aggregatePayout: AggregatePayout) -> String {
		var lines: [String] = []

		for accountPayout in aggregatePayout.accountPayouts {
			let accountTotal = CurrencyFormatter.format(accountPayout.totalAmount)
			let hasUnadjusted = accountPayout.unadjustedAmount > 0
			let asterisk = hasUnadjusted ? "*" : ""
			lines.append("Account: \(accountPayout.accountName) - \(accountTotal)\(asterisk)")

			let payoutsByCusip = Dictionary(grouping: accountPayout.payouts) { $0.cusip }
			let sortedCusips = payoutsByCusip.keys.sorted()

			lines.append("\(accountPayout.accountName):")

			for cusip in sortedCusips {
				guard let cusipPayouts = payoutsByCusip[cusip] else { continue }

				let totalCount = cusipPayouts.reduce(0) { $0 + $1.count }
				let totalPayoutAmount = cusipPayouts.reduce(0.0) { $0 + $1.totalAmount }
				let formattedPayout = CurrencyFormatter.format(totalPayoutAmount)
				let hasUnadjustedCusip = cusipPayouts.contains { $0.adjustmentStatus == .unadjusted }
				let cusipAsterisk = hasUnadjustedCusip ? "*" : ""

				lines.append("  • CUSIP: \(cusip), Count: \(totalCount), Payout: \(formattedPayout)\(cusipAsterisk)")
			}

			lines.append("")
		}

		let aggregateTotal = CurrencyFormatter.format(aggregatePayout.totalAmount)
		let hasUnadjusted = aggregatePayout.unadjustedAmount > 0
		let asterisk = hasUnadjusted ? "*" : ""
		lines.append("Aggregate Total: \(aggregateTotal)\(asterisk)")

		return lines.joined(separator: "\n")
	}
}

