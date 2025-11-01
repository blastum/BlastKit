#!/usr/bin/env swift

import Foundation

// Simple script to analyze TIPS test data CSV files directly
struct DataAnalyzer {
    static func loadCSVData(from filename: String, hasHeader: Bool = false) -> [(cusip: String, count: Int)] {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/TIPSCalendarKit/Resources/\(filename).csv")

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            var dataLines = lines
            if hasHeader && !lines.isEmpty {
                dataLines = Array(lines.dropFirst())
            }

            return dataLines.compactMap { line in
                let components = line.components(separatedBy: ",")
                guard components.count >= 2,
                      let count = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
                    return nil
                }
                return (cusip: components[0].trimmingCharacters(in: .whitespaces), count: count)
            }
        } catch {
            print("Error reading \(filename).csv: \(error)")
            return []
        }
    }

    static func analyzeCSVFiles() {
        print("=== TIPS Test Data Analysis ===\n")

        let iraData = loadCSVData(from: "IRALadder")
        let rothData = loadCSVData(from: "RothLadder", hasHeader: true)

        let iraCusips = iraData.map { $0.cusip }
        let rothCusips = rothData.map { $0.cusip }
        let allCusips = iraCusips + rothCusips

        // Find duplicates
        let cusipCounts = Dictionary(allCusips.map { ($0, 1) }, uniquingKeysWith: +)
        let duplicates = cusipCounts.filter { $0.value > 1 }.sorted { $0.key < $1.key }

        // Calculate totals
        let totalUniqueCusips = Set(allCusips).count
        let totalCusipsWithDuplicates = allCusips.count

        // Per account analysis
        print("📊 Account Summary:")
        print("   IRA Ladder: \(iraCusips.count) CUSIPs")
        print("   Existing Roth TIPS Ladder: \(rothCusips.count) CUSIPs")
        print()

        print("📈 Totals:")
        print("   Total unique CUSIPs across all accounts: \(totalUniqueCusips)")
        print("   Total CUSIPs (including duplicates): \(totalCusipsWithDuplicates)")
        print()

        if !duplicates.isEmpty {
            print("🔄 Duplicated CUSIPs (\(duplicates.count) duplicates):")
            for (cusip, count) in duplicates {
                print("   \(cusip): appears \(count) times")
                let accounts = [
                    iraCusips.contains(cusip) ? "IRA" : nil,
                    rothCusips.contains(cusip) ? "Roth" : nil
                ].compactMap { $0 }
                print("     Found in: \(accounts.joined(separator: ", "))")
            }
        } else {
            print("✅ No duplicated CUSIPs found")
        }
        print()

        // Holdings summary
        print("💰 Holdings Summary:")
        let iraTotal = iraData.reduce(0) { $0 + $1.count }
        let rothTotal = rothData.reduce(0) { $0 + $1.count }
        print("   IRA Ladder: \(iraTotal) total holdings")
        print("   Existing Roth TIPS Ladder: \(rothTotal) total holdings")
        print("   Combined: \(iraTotal + rothTotal) total holdings")
        print()

        // Sample data
        print("📋 Sample Data:")
        if !iraData.isEmpty {
            print("   IRA Ladder (first 3): \(iraData.prefix(3).map { "\($0.cusip):\($0.count)" }.joined(separator: ", "))")
        }
        if !rothData.isEmpty {
            print("   Roth Ladder (first 3): \(rothData.prefix(3).map { "\($0.cusip):\($0.count)" }.joined(separator: ", "))")
        }
    }
}

DataAnalyzer.analyzeCSVFiles()
