import Testing
import Foundation
@testable import TIPSCalendarKit

@Suite
struct TIPSCalendarKitTests {
    
    @Test func testCSVPortfolioLoading() throws {
        let (iraAccount, rothAccount) = try CSVLoader.loadPortfolio()
        
        #expect(iraAccount.name == "IRA Ladder")
        #expect(rothAccount.name == "Existing Roth TIPS Ladder")
        
        // Verify IRA account has 19 holdings (from IRALadder.csv)
        #expect(iraAccount.holdings.count == 19)
        
        // Verify Roth account has 21 holdings (from RothLadder.csv)
        #expect(rothAccount.holdings.count == 21)
    }
    
    @Test func testPurchaseDates() throws {
        let (iraAccount, rothAccount) = try CSVLoader.loadPortfolio()
        
        // IRA securities bought on 13-May-2025 (from CSV data)
        let iraDate = Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 13))!
        for holding in iraAccount.holdings {
            #expect(Calendar.current.isDate(holding.purchaseDate, inSameDayAs: iraDate))
        }
        
        // Roth securities bought on 15-Apr-2025
        let rothDate = Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 15))!
        for holding in rothAccount.holdings {
            #expect(Calendar.current.isDate(holding.purchaseDate, inSameDayAs: rothDate))
        }
    }
    
    @Test func testIRALadderDataIntegrity() throws {
        let (iraAccount, _) = try CSVLoader.loadPortfolio()
        
        // Test specific holdings from the actual CSV data
        let holding1 = iraAccount.holdings.first { $0.cusip == "9128282L3" }
        #expect(holding1 != nil)
        #expect(holding1?.count == 24)
        
        let holding2 = iraAccount.holdings.first { $0.cusip == "912828N71" }
        #expect(holding2 != nil)
        #expect(holding2?.count == 24)
        
        let holding3 = iraAccount.holdings.first { $0.cusip == "91282CKL4" }
        #expect(holding3 != nil)
        #expect(holding3?.count == 31)
        
        // Test total holdings count
        let totalCount = iraAccount.holdings.reduce(0) { $0 + $1.count }
        #expect(totalCount == 485) // Sum of all IRA counts from CSV
    }
    
    @Test func testRothLadderDataIntegrity() throws {
        let (_, rothAccount) = try CSVLoader.loadPortfolio()
        
        // Test specific holdings from the actual CSV data
        let holding1 = rothAccount.holdings.first { $0.cusip == "912810QP6" }
        #expect(holding1 != nil)
        #expect(holding1?.count == 76)
        
        let holding2 = rothAccount.holdings.first { $0.cusip == "912810RA8" }
        #expect(holding2 != nil)
        #expect(holding2?.count == 82)
        
        let holding3 = rothAccount.holdings.first { $0.cusip == "912810RW0" }
        #expect(holding3 != nil)
        #expect(holding3?.count == 89)
        
        // Test total holdings count
        let totalCount = rothAccount.holdings.reduce(0) { $0 + $1.count }
        #expect(totalCount == 1969) // Sum of all Roth counts from CSV
    }
    
    @Test func testAccountCUSIPsExtraction() throws {
        let (iraAccount, rothAccount) = try CSVLoader.loadPortfolio()
        
        // Verify IRA account CUSIPs
        #expect(iraAccount.cusips.count == 19)
        #expect(iraAccount.cusips.contains("9128282L3"))
        #expect(iraAccount.cusips.contains("912828N71"))
        #expect(iraAccount.cusips.contains("91282CKL4"))
        
        // Verify Roth account CUSIPs
        #expect(rothAccount.cusips.count == 21)
        #expect(rothAccount.cusips.contains("912810QP6"))
        #expect(rothAccount.cusips.contains("912810RA8"))
        #expect(rothAccount.cusips.contains("912810RW0"))
        
        // Verify overlap between accounts (there are 5 overlapping CUSIPs)
        let intersection = iraAccount.cusips.intersection(rothAccount.cusips)
        #expect(intersection.count == 5)
        #expect(intersection.contains("912828Z37"))
        #expect(intersection.contains("91282CDC2"))
        #expect(intersection.contains("91282CFR7"))
        #expect(intersection.contains("91282CJH5"))
        #expect(intersection.contains("91282CLV1"))
    }
    
    @Test func testTotalPortfolioValue() throws {
        let (iraAccount, rothAccount) = try CSVLoader.loadPortfolio()
        
        let iraTotal = iraAccount.holdings.reduce(0) { $0 + $1.count }
        let rothTotal = rothAccount.holdings.reduce(0) { $0 + $1.count }
        
        #expect(iraTotal == 485) // Total from IRALadder.csv
        #expect(rothTotal == 1969) // Total from RothLadder.csv
        #expect(iraTotal + rothTotal == 2454) // Combined total
    }
    
    @Test func testUniqueCUSIPsAcrossAllAccounts() throws {
        let (iraAccount, rothAccount) = try CSVLoader.loadPortfolio()
        let allCUSIPs = iraAccount.cusips.union(rothAccount.cusips)
        
        #expect(allCUSIPs.count == 35) // 19 from IRA + 21 from Roth - 5 overlaps
        #expect(allCUSIPs.contains("9128282L3")) // IRA CUSIP
        #expect(allCUSIPs.contains("912810QP6")) // Roth CUSIP
    }
}
