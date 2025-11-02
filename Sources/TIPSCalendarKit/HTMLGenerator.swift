import Foundation
import TIPSKit

public class HTMLGenerator {
	public let title: String
	
	public init(title: String = "TIPS Payout Calendar") {
		self.title = title
	}
	
	public func generate(
		from payoutCalendar: PayoutCalendar,
		generatedAt: Date = Date()
	) -> String {
		let html = generateHTML(payoutCalendar: payoutCalendar, generatedAt: generatedAt)
		return html
	}
	
	private func generateHTML(payoutCalendar: PayoutCalendar, generatedAt: Date) -> String {
		var html = """
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>\(title)</title>
	<style>
		body {
			font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
			margin: 20px;
			line-height: 1.4;
		}
		h1 {
			border-bottom: 2px solid #333;
			padding-bottom: 10px;
		}
		.year-section {
			margin-bottom: 30px;
		}
		.year-header {
			font-size: 1.3em;
			font-weight: bold;
			margin: 20px 0 10px 0;
			color: #1a1a1a;
		}
		table {
			border-collapse: collapse;
			width: auto;
			margin-bottom: 15px;
		}
		th, td {
			padding: 8px 12px;
			text-align: right;
			border: 1px solid #ddd;
		}
		th {
			background-color: #f5f5f5;
			font-weight: 600;
			position: sticky;
			top: 0;
		}
		.month-cell {
			text-align: left;
			font-weight: 500;
		}
		tfoot td {
			font-weight: bold;
			background-color: #f0f0f0;
			border-top: 2px solid #666;
		}
		.summary {
			margin-top: 40px;
			padding: 20px;
			background-color: #f9f9f9;
			border: 1px solid #ddd;
		}
		.generated {
			font-size: 0.9em;
			color: #666;
			margin-top: 5px;
		}
	</style>
</head>
<body>
	<h1>\(title)</h1>
	<div class="generated">Generated: \(formatDateTime(generatedAt))</div>
	
"""
		
		// Group payouts by year
		let payoutsByYear = Dictionary(grouping: payoutCalendar.aggregatePayouts) { payout in
			Calendar.current.component(.year, from: payout.date)
		}
		
		// Sort years
		let sortedYears = payoutsByYear.keys.sorted()
		
		// Generate table
		html += generateTable(payoutsByYear: payoutsByYear, sortedYears: sortedYears, payoutCalendar: payoutCalendar)
		
		// Add summary
		html += generateSummary(payoutCalendar: payoutCalendar)
		
		html += """
</body>
</html>
"""
		
		return html
	}
	
	private func generateTable(
		payoutsByYear: [Int: [AggregatePayout]],
		sortedYears: [Int],
		payoutCalendar: PayoutCalendar
	) -> String {
		var html = ""
		
		for year in sortedYears {
			guard let yearPayouts = payoutsByYear[year] else { continue }
			
			html += """
	<div class="year-section">
		<div class="year-header">\(year)</div>
		<table>
			<thead>
				<tr>
					<th class="month-cell">Month</th>
					<th>IRA Account</th>
					<th>Roth Account</th>
					<th>Total</th>
				</tr>
			</thead>
			<tbody>
"""
			
			// Group by month
			let payoutsByMonth = Dictionary(grouping: yearPayouts) { payout in
				Calendar.current.component(.month, from: payout.date)
			}
			
			let sortedMonths = payoutsByMonth.keys.sorted()
			var yearTotalIRA = 0.0
			var yearTotalRoth = 0.0
			var yearTotalAggregate = 0.0
			
			for month in sortedMonths {
				guard let monthPayouts = payoutsByMonth[month] else { continue }
				
				// Sum IRA and Roth for this month
				var monthIRA = 0.0
				var monthRoth = 0.0
				var monthHasUnadjusted = false
				
				for payout in monthPayouts {
					for accountPayout in payout.accountPayouts {
						if accountPayout.accountName.contains("IRA") {
							monthIRA += accountPayout.totalAmount
						} else if accountPayout.accountName.contains("Roth") {
							monthRoth += accountPayout.totalAmount
						}
					}
					if payout.unadjustedAmount > 0 {
						monthHasUnadjusted = true
					}
				}
				
				let monthTotal = monthIRA + monthRoth
				let asterisk = monthHasUnadjusted ? " *" : ""
				let monthName = monthName(from: month)
				
				yearTotalIRA += monthIRA
				yearTotalRoth += monthRoth
				yearTotalAggregate += monthTotal
				
				html += """
				<tr>
					<td class="month-cell">\(monthName)\(asterisk)</td>
					<td>\(formatCurrency(monthIRA))</td>
					<td>\(formatCurrency(monthRoth))</td>
					<td>\(formatCurrency(monthTotal))</td>
				</tr>
"""
			}
			
			html += """
			</tbody>
			<tfoot>
				<tr>
					<td class="month-cell">Year Total</td>
					<td>\(formatCurrency(yearTotalIRA))</td>
					<td>\(formatCurrency(yearTotalRoth))</td>
					<td>\(formatCurrency(yearTotalAggregate))</td>
				</tr>
			</tfoot>
		</table>
	</div>
"""
		}
		
		return html
	}
	
	private func generateSummary(payoutCalendar: PayoutCalendar) -> String {
		let html = """
	<div class="summary">
		<h2>Summary</h2>
		<table>
			<tr>
				<td>IRA Total Adjusted:</td>
				<td>\(formatCurrency(getAccountTotal(payoutCalendar: payoutCalendar, accountName: "IRA", adjusted: true)))</td>
			</tr>
			<tr>
				<td>IRA Total Unadjusted:</td>
				<td>\(formatCurrency(getAccountTotal(payoutCalendar: payoutCalendar, accountName: "IRA", adjusted: false)))</td>
			</tr>
			<tr>
				<td>Roth Total Adjusted:</td>
				<td>\(formatCurrency(getAccountTotal(payoutCalendar: payoutCalendar, accountName: "Roth", adjusted: true)))</td>
			</tr>
			<tr>
				<td>Roth Total Unadjusted:</td>
				<td>\(formatCurrency(getAccountTotal(payoutCalendar: payoutCalendar, accountName: "Roth", adjusted: false)))</td>
			</tr>
			<tr>
				<td><strong>Aggregate Total Adjusted:</strong></td>
				<td><strong>\(formatCurrency(payoutCalendar.totalAdjustedAmount))</strong></td>
			</tr>
			<tr>
				<td><strong>Aggregate Total Unadjusted:</strong></td>
				<td><strong>\(formatCurrency(payoutCalendar.totalUnadjustedAmount))</strong></td>
			</tr>
		</table>
		<p><em>* Months marked with asterisk contain unadjusted payouts (missing TIPSDetail data)</em></p>
	</div>
"""
		return html
	}
	
	private func getAccountTotal(payoutCalendar: PayoutCalendar, accountName: String, adjusted: Bool) -> Double {
		for accountCalendar in payoutCalendar.accountCalendars.values {
			if accountCalendar.accountName.contains(accountName) {
				return adjusted ? accountCalendar.totalAdjustedAmount : accountCalendar.totalUnadjustedAmount
			}
		}
		return 0.0
	}
	
	private func monthName(from month: Int) -> String {
		let formatter = DateFormatter()
		return formatter.monthSymbols[month - 1]
	}
	
	private func formatCurrency(_ amount: Double) -> String {
		return amount > 0 ? CurrencyFormatter.format(amount) : "-"
	}
	
	private func formatDateTime(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		return formatter.string(from: date)
	}
}

