import Testing
import Foundation
@testable import TIPSCalendarKit
@testable import TIPSKit

@Suite
struct ICalTests {

	@Test func testDateToICalDate() {
		let date = Date(timeIntervalSince1970: 0)
		let iCalDate = date.toICalDate()
		#expect(iCalDate == "19700101")
	}

	@Test func testDateToICalDateTime() {
		let date = Date(timeIntervalSince1970: 946684800)
		let iCalDateTime = date.toICalDateTime()
		#expect(iCalDateTime == "20000101T000000Z")
	}

	@Test func testCurrencyFormatter() {
		#expect(CurrencyFormatter.format(0) == "$0.00")
		#expect(CurrencyFormatter.format(1234.56) == "$1,234.56")
		#expect(CurrencyFormatter.format(1234567.89) == "$1,234,567.89")
		#expect(CurrencyFormatter.format(0.01) == "$0.01")
	}

	@Test func testICalEventRendering() {
		let event = ICalEvent(
			uid: "20250715@tipscalendarkit.github.io",
			dtStart: "20250715",
			dtEnd: "20250716",
			dtStamp: "20250115T120000Z",
			summary: "TIPS: $12,345.67",
			description: "Test description"
		)

		let rendered = event.render()

		#expect(rendered.contains("BEGIN:VEVENT"))
		#expect(rendered.contains("END:VEVENT"))
		#expect(rendered.contains("UID:20250715@tipscalendarkit.github.io"))
		#expect(rendered.contains("DTSTART;VALUE=DATE:20250715"))
		#expect(rendered.contains("DTEND;VALUE=DATE:20250716"))
		#expect(rendered.contains("DTSTAMP:20250115T120000Z"))
		#expect(rendered.contains("SUMMARY:TIPS: $12,345.67"))
		#expect(rendered.contains("SEQUENCE:0"))
	}

	@Test func testICalEventEscaping() {
		let event = ICalEvent(
			uid: "20250715@tipscalendarkit.github.io",
			dtStart: "20250715",
			dtEnd: "20250716",
			dtStamp: "20250115T120000Z",
			summary: "Test, with; commas",
			description: "Test\nmultiline\ndescription"
		)

		let rendered = event.render()

		#expect(rendered.contains("Test, with\\; commas"))
		#expect(rendered.contains("Test\\nmultiline\\ndescription"))
	}

	@Test func testICalCalendarRendering() {
		let events = [
			ICalEvent(
				uid: "20250715@tipscalendarkit.github.io",
				dtStart: "20250715",
				dtEnd: "20250716",
				dtStamp: "20250115T120000Z",
				summary: "TIPS: $1,000.00",
				description: "Description 1"
			),
			ICalEvent(
				uid: "20250815@tipscalendarkit.github.io",
				dtStart: "20250815",
				dtEnd: "20250816",
				dtStamp: "20250115T120000Z",
				summary: "TIPS: $2,000.00",
				description: "Description 2"
			)
		]

		let calendar = ICalCalendar(events: events)
		let rendered = calendar.render()

		#expect(rendered.contains("BEGIN:VCALENDAR"))
		#expect(rendered.contains("END:VCALENDAR"))
		#expect(rendered.contains("VERSION:2.0"))
		#expect(rendered.contains("CALSCALE:GREGORIAN"))
		#expect(rendered.contains("METHOD:PUBLISH"))
		#expect(rendered.contains("UID:20250715@tipscalendarkit.github.io"))
		#expect(rendered.contains("UID:20250815@tipscalendarkit.github.io"))
	}

	@Test func testEmptyCalendar() {
		let calendar = ICalCalendar(events: [])
		let rendered = calendar.render()

		#expect(rendered.contains("BEGIN:VCALENDAR"))
		#expect(rendered.contains("END:VCALENDAR"))
		#expect(!rendered.contains("BEGIN:VEVENT"))
	}

	@Test func testICalEventSequence() {
		let event = ICalEvent(
			uid: "20250715@tipscalendarkit.github.io",
			dtStart: "20250715",
			dtEnd: "20250716",
			dtStamp: "20250115T120000Z",
			summary: "TIPS: $1,000.00",
			description: "Test",
			sequence: 5
		)

		let rendered = event.render()
		#expect(rendered.contains("SEQUENCE:5"))
	}

	@Test func testLineFolding() {
		let longDescription = String(repeating: "A", count: 100)
		let event = ICalEvent(
			uid: "20250715@tipscalendarkit.github.io",
			dtStart: "20250715",
			dtEnd: "20250716",
			dtStamp: "20250115T120000Z",
			summary: "Test",
			description: longDescription
		)

		let rendered = event.render()
		let descriptionLines = rendered.components(separatedBy: "\r\n")
			.filter { $0.hasPrefix("DESCRIPTION:") || $0.hasPrefix(" ") }

		for line in descriptionLines {
			let content = line.hasPrefix(" ") ? String(line.dropFirst()) : line
			#expect(content.count <= 76)
		}
	}

	// MARK: - CalendarGenerator Tests

	@Test func testCalendarGeneratorUIDGeneration() {
		let generator = CalendarGenerator()
		let accountId = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let accountPayout = AccountPayout(accountId: accountId, accountName: "Test Account", date: date, payouts: [payout])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)
		let event = iCalCalendar.events[0]

		#expect(event.uid == "20250715@tipscalendarkit.github.io")
	}

	@Test func testCalendarGeneratorCustomDomain() {
		let generator = CalendarGenerator(uidDomain: "example.com")
		let accountId = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let accountPayout = AccountPayout(accountId: accountId, accountName: "Test Account", date: date, payouts: [payout])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)
		let event = iCalCalendar.events[0]

		#expect(event.uid == "20250715@example.com")
	}

	@Test func testCalendarGeneratorEmptyCalendar() {
		let generator = CalendarGenerator()
		let emptyCalendar = PayoutCalendar(aggregatePayouts: [], accountCalendars: [:])
		let iCalCalendar = generator.generate(from: emptyCalendar)

		#expect(iCalCalendar.events.isEmpty)
	}

	@Test func testCalendarGeneratorSinglePayout() {
		let generator = CalendarGenerator()
		let accountId = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let accountPayout = AccountPayout(accountId: accountId, accountName: "Test Account", date: date, payouts: [payout])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)

		#expect(iCalCalendar.events.count == 1)
		let event = iCalCalendar.events[0]
		#expect(event.uid == "20250715@tipscalendarkit.github.io")
		#expect(event.dtStart == "20250715")
		#expect(event.dtEnd == "20250716")
		#expect(event.summary == "TIPS: $255.00")
		#expect(event.summary.contains("*") == false)
		#expect(event.description.contains("Test Account"))
		#expect(event.description.contains("912810FD5"))
		#expect(event.description.contains("$255.00"))
	}

	@Test func testCalendarGeneratorUnadjustedPayout() {
		let generator = CalendarGenerator()
		let accountId = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .unadjusted,
			indexRatio: nil,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let accountPayout = AccountPayout(accountId: accountId, accountName: "Test Account", date: date, payouts: [payout])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)

		#expect(iCalCalendar.events.count == 1)
		let event = iCalCalendar.events[0]
		#expect(event.summary == "TIPS: $255.00*")
		#expect(event.description.contains("*"))
	}

	@Test func testCalendarGeneratorMultipleAccounts() {
		let generator = CalendarGenerator()
		let accountId1 = UUID()
		let accountId2 = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout1 = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId1,
			accountName: "IRA Ladder",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let payout2 = TIPSPayout(
			cusip: "91282CDH4",
			date: date,
			accountId: accountId2,
			accountName: "Roth Ladder",
			amountPerBond: 50.25,
			count: 5,
			adjustmentStatus: .adjusted,
			indexRatio: 1.08,
			interestRate: 0.0150,
			includesPrincipal: false
		)

		let accountPayout1 = AccountPayout(accountId: accountId1, accountName: "IRA Ladder", date: date, payouts: [payout1])
		let accountPayout2 = AccountPayout(accountId: accountId2, accountName: "Roth Ladder", date: date, payouts: [payout2])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout1, accountPayout2])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)

		#expect(iCalCalendar.events.count == 1)
		let event = iCalCalendar.events[0]
		#expect(event.description.contains("IRA Ladder - $255.00"))
		#expect(event.description.contains("Roth Ladder - $251.25"))
		#expect(event.description.contains("• 912810FD5 (10) $255.00"))
		#expect(event.description.contains("• 91282CDH4 (5) $251.25"))
		#expect(event.description.contains("Aggregate $506.25"))
		#expect(event.summary == "TIPS: $506.25")
	}

	@Test func testCalendarGeneratorMultipleCusipsSameAccount() {
		let generator = CalendarGenerator()
		let accountId = UUID()
		let date = Date.from(year: 2025, month: 7, day: 15)!

		let payout1 = TIPSPayout(
			cusip: "912810FD5",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let payout2 = TIPSPayout(
			cusip: "91282CDH4",
			date: date,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 50.25,
			count: 5,
			adjustmentStatus: .adjusted,
			indexRatio: 1.08,
			interestRate: 0.0150,
			includesPrincipal: false
		)

		let accountPayout = AccountPayout(accountId: accountId, accountName: "Test Account", date: date, payouts: [payout1, payout2])
		let aggregatePayout = AggregatePayout(date: date, accountPayouts: [accountPayout])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)

		#expect(iCalCalendar.events.count == 1)
		let event = iCalCalendar.events[0]
		#expect(event.description.contains("• 912810FD5 (10) $255.00"))
		#expect(event.description.contains("• 91282CDH4 (5) $251.25"))
	}

	@Test func testCalendarGeneratorMultipleDates() {
		let generator = CalendarGenerator()
		let accountId = UUID()
		let date1 = Date.from(year: 2025, month: 7, day: 15)!
		let date2 = Date.from(year: 2025, month: 10, day: 15)!

		let payout1 = TIPSPayout(
			cusip: "912810FD5",
			date: date1,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.05,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let payout2 = TIPSPayout(
			cusip: "912810FD5",
			date: date2,
			accountId: accountId,
			accountName: "Test Account",
			amountPerBond: 25.50,
			count: 10,
			adjustmentStatus: .adjusted,
			indexRatio: 1.08,
			interestRate: 0.0125,
			includesPrincipal: false
		)

		let accountPayout1 = AccountPayout(accountId: accountId, accountName: "Test Account", date: date1, payouts: [payout1])
		let accountPayout2 = AccountPayout(accountId: accountId, accountName: "Test Account", date: date2, payouts: [payout2])
		let aggregatePayout1 = AggregatePayout(date: date1, accountPayouts: [accountPayout1])
		let aggregatePayout2 = AggregatePayout(date: date2, accountPayouts: [accountPayout2])
		let payoutCalendar = PayoutCalendar(aggregatePayouts: [aggregatePayout1, aggregatePayout2], accountCalendars: [:])

		let iCalCalendar = generator.generate(from: payoutCalendar)

		#expect(iCalCalendar.events.count == 2)
		#expect(iCalCalendar.events[0].uid == "20250715@tipscalendarkit.github.io")
		#expect(iCalCalendar.events[1].uid == "20251015@tipscalendarkit.github.io")
	}
}

extension Date {
	static func from(year: Int, month: Int, day: Int) -> Date? {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		components.hour = 0
		components.minute = 0
		components.second = 0
		return Calendar.current.date(from: components)
	}
}

