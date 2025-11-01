import Foundation
import TIPSKit
import TIPSCalendarKit

@main
struct TIPSCalendarGenerator {
	static func main() async {
		do {
			let arguments = CommandLine.arguments
			let (inputFiles, outputFile) = try parseArguments(arguments)
			
			guard !inputFiles.isEmpty else {
				print("Error: At least one input file is required. Use --input or -i to specify input files.")
				exit(1)
			}
			
			var accounts: [TIPSAccount] = []
			
			for inputFile in inputFiles {
				let fileURL = URL(fileURLWithPath: inputFile)
				let fileExtension = fileURL.pathExtension.lowercased()
				
				let loadedAccounts: [TIPSAccount]
				switch fileExtension {
				case "csv":
					let account = try loadCSVAccount(from: inputFile, fileName: fileURL.lastPathComponent)
					loadedAccounts = [account]
				case "json":
					loadedAccounts = try loadJSONAccounts(from: inputFile)
				default:
					throw CalendarGeneratorError.unsupportedFileType(fileExtension)
				}
				
				accounts.append(contentsOf: loadedAccounts)
			}
			
			guard !accounts.isEmpty else {
				print("Error: No accounts were loaded from input files.")
				exit(1)
			}
			
			let calendar = try await generateCalendar(from: accounts)
			
			let calendarString = calendar.render()
			
			if let outputFile = outputFile {
				try calendarString.write(toFile: outputFile, atomically: true, encoding: .utf8)
				print("✅ Calendar generated and written to: \(outputFile)")
			} else {
				print(calendarString)
			}
		} catch {
			print("❌ Error: \(error.localizedDescription)")
			exit(1)
		}
	}
	
	static func parseArguments(_ arguments: [String]) throws -> (inputFiles: [String], outputFile: String?) {
		var inputFiles: [String] = []
		var outputFile: String?
		var i = 1
		
		while i < arguments.count {
			let arg = arguments[i]
			
			switch arg {
			case "--input", "-i":
				guard i + 1 < arguments.count else {
					throw CalendarGeneratorError.missingArgumentValue(arg)
				}
				inputFiles.append(arguments[i + 1])
				i += 2
			case "--output", "-o":
				guard i + 1 < arguments.count else {
					throw CalendarGeneratorError.missingArgumentValue(arg)
				}
				outputFile = arguments[i + 1]
				i += 2
			case "--help", "-h":
				printUsage()
				exit(0)
			default:
				throw CalendarGeneratorError.unknownArgument(arg)
			}
		}
		
		return (inputFiles, outputFile)
	}
	
	static func printUsage() {
		print("""
		Usage: TIPSCalendarGenerator [options]
		
		Options:
		  -i, --input <file>     Input file (CSV or JSON). Can be specified multiple times.
		  -o, --output <file>    Output .ics file path. If not specified, writes to stdout.
		  -h, --help            Show this help message.
		
		Examples:
		  swift run TIPSCalendarGenerator --input ira.csv --input roth.csv > calendar.ics
		  swift run TIPSCalendarGenerator --input ira.csv --output calendar.ics
		  swift run TIPSCalendarGenerator --input accounts.json --output calendar.ics
		""")
	}
	
	static func loadCSVAccount(from filePath: String, fileName: String) throws -> TIPSAccount {
		let url = URL(fileURLWithPath: filePath)
		let content = try String(contentsOf: url)
		let lines = content.components(separatedBy: .newlines)
			.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
		
		guard !lines.isEmpty else {
			throw CalendarGeneratorError.invalidCSVFile("File is empty")
		}
		
		let firstLine = lines[0]
		let firstComponents = firstLine.components(separatedBy: ",")
		let hasHeader = firstComponents.first?.trimmingCharacters(in: .whitespaces).lowercased() == "cusip"
		
		let purchaseDate: Date
		if fileName.lowercased().contains("ira") {
			purchaseDate = Date.from(year: 2025, month: 5, day: 13)
		} else if fileName.lowercased().contains("roth") {
			purchaseDate = Date.from(year: 2025, month: 4, day: 15)
		} else {
			purchaseDate = Date()
		}
		
		return try CSVLoader.loadAccount(from: filePath, hasHeader: hasHeader, purchaseDate: purchaseDate)
	}
	
	static func loadJSONAccounts(from filePath: String) throws -> [TIPSAccount] {
		let url = URL(fileURLWithPath: filePath)
		let data = try Data(contentsOf: url)
		
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		
		if let singleAccount = try? decoder.decode(TIPSAccountCodable.self, from: data) {
			return [singleAccount.toTIPSAccount()]
		} else if let accounts = try? decoder.decode([TIPSAccountCodable].self, from: data) {
			return accounts.map { $0.toTIPSAccount() }
		} else {
			throw CalendarGeneratorError.invalidJSONFormat
		}
	}
	
	static func generateCalendar(from accounts: [TIPSAccount]) async throws -> ICalCalendar {
		// Use URLCache.shared for cross-run persistence
		// URLCache.shared is a system-wide singleton that persists across app runs
		// It stores data in ~/Library/Caches/com.apple.nsurlsessiond/Downloads/
		// Command-line apps are NOT sandboxed, so they can access this location
		// Note: URLCache.shared has fixed capacity (we can't customize it), but it's
		// the simplest way to get cross-run persistence without managing cache files
		let service = TIPSService(urlCache: URLCache.shared)
		for account in accounts {
			service.addAccount(account)
		}
		
		let summariesResult = await service.summaries()
		guard case let .success(summaries) = summariesResult else {
			if case let .failure(error) = summariesResult {
				throw CalendarGeneratorError.failedToFetchSummariesWithDetails(error.localizedDescription)
			}
			throw CalendarGeneratorError.failedToFetchSummaries
		}
		
		let payoutSchedulesResult = service.payoutSchedules(summaries: summaries)
		guard case let .success(payoutSchedules) = payoutSchedulesResult else {
			throw CalendarGeneratorError.failedToGeneratePayoutSchedules
		}
		
		let indexRatiosResult = await service.indexRatios(payoutSchedules: payoutSchedules)
		guard case let .success(indexRatios) = indexRatiosResult else {
			throw CalendarGeneratorError.failedToFetchIndexRatios
		}
		
		let allPayouts = service.calculateAllPayouts(
			summaries: summaries,
			payoutSchedules: payoutSchedules,
			indexRatios: indexRatios
		)
		
		let payoutCalendar = service.aggregatePayouts(allPayouts)
		
		let generator = CalendarGenerator()
		return generator.generate(from: payoutCalendar)
	}
}

enum CalendarGeneratorError: Error, LocalizedError {
	case missingArgumentValue(String)
	case unknownArgument(String)
	case unsupportedFileType(String)
	case invalidJSONFormat
	case invalidCSVFile(String)
	case failedToFetchSummaries
	case failedToFetchSummariesWithDetails(String)
	case failedToGeneratePayoutSchedules
	case failedToFetchIndexRatios
	
	var errorDescription: String? {
		switch self {
		case .missingArgumentValue(let arg):
			return "Missing value for argument: \(arg)"
		case .unknownArgument(let arg):
			return "Unknown argument: \(arg)"
		case .unsupportedFileType(let type):
			return "Unsupported file type: \(type). Supported types: csv, json"
		case .invalidJSONFormat:
			return "Invalid JSON format. Expected array of TIPSAccount objects or single TIPSAccount object."
		case .invalidCSVFile(let message):
			return "Invalid CSV file: \(message)"
		case .failedToFetchSummaries:
			return "Failed to fetch TIPS summary data from API"
		case .failedToFetchSummariesWithDetails(let details):
			return "Failed to fetch TIPS summary data from API: \(details)"
		case .failedToGeneratePayoutSchedules:
			return "Failed to generate payout schedules"
		case .failedToFetchIndexRatios:
			return "Failed to fetch index ratio data from API"
		}
	}
}

extension Date {
	static func from(year: Int, month: Int, day: Int) -> Date {
		var components = DateComponents()
		components.year = year
		components.month = month
		components.day = day
		components.hour = 0
		components.minute = 0
		components.second = 0
		
		let calendar = Calendar.current
		return calendar.date(from: components) ?? Date()
	}
}

struct TIPSAccountCodable: Codable {
	let name: String
	let holdings: [TIPSHoldingCodable]
	
	func toTIPSAccount() -> TIPSAccount {
		let tipsHoldings = holdings.map { $0.toTIPSHolding() }
		return TIPSAccount(name: name, holdings: tipsHoldings)
	}
}

struct TIPSHoldingCodable: Codable {
	let cusip: String
	let purchaseDate: Date
	let count: Int
	
	func toTIPSHolding() -> TIPSHolding {
		return TIPSHolding(cusip: cusip, purchaseDate: purchaseDate, count: count)
	}
}

