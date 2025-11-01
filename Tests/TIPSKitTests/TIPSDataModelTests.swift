//
//  TIPSDataModelTests.swift
//  TIPSKitTests
//
//  Created by James Blasius on 8/17/25.
//

import Testing
import Foundation
@testable import TIPSKit

@Suite
struct TIPSDataModelTests {
    
    // MARK: - TIPSAccount Tests
    
    @Test func testTIPSAccountInitialization() throws {
        let holdings = [
            TIPSHolding(cusip: "912810FD5", purchaseDate: Date(), count: 100),
            TIPSHolding(cusip: "912810FH6", purchaseDate: Date(), count: 200)
        ]
        
        let account = TIPSAccount(name: "Test Account", holdings: holdings)
        
        #expect(account.name == "Test Account")
        #expect(account.holdings.count == 2)
        #expect(account.holdings == holdings)
        #expect(account.id != UUID())
    }
    
    @Test func testTIPSAccountCUSIPsExtraction() throws {
        let holdings = [
            TIPSHolding(cusip: "912810FD5", purchaseDate: Date(), count: 100),
            TIPSHolding(cusip: "912810FH6", purchaseDate: Date(), count: 200),
            TIPSHolding(cusip: "912810FQ6", purchaseDate: Date(), count: 150)
        ]
        
        let account = TIPSAccount(name: "Test Account", holdings: holdings)
        let cusips = account.cusips
        
        #expect(cusips.count == 3)
        #expect(cusips.contains("912810FD5"))
        #expect(cusips.contains("912810FH6"))
        #expect(cusips.contains("912810FQ6"))
    }
    
    @Test func testTIPSAccountEmptyHoldings() throws {
        let account = TIPSAccount(name: "Empty Account", holdings: [])
        
        #expect(account.name == "Empty Account")
        #expect(account.holdings.isEmpty)
        #expect(account.cusips.isEmpty)
    }
    
    // MARK: - TIPSHolding Tests
    
    @Test func testTIPSHoldingInitialization() throws {
        let purchaseDate = Date()
        let holding = TIPSHolding(cusip: "912810FD5", purchaseDate: purchaseDate, count: 100)
        
        #expect(holding.cusip == "912810FD5")
        #expect(holding.purchaseDate == purchaseDate)
        #expect(holding.count == 100)
    }
    
    @Test func testTIPSHoldingProperties() throws {
        let holding = TIPSHolding(cusip: "912810FH6", purchaseDate: Date(), count: 0)
        
        #expect(holding.cusip == "912810FH6")
        #expect(holding.count == 0)
    }
    
    // MARK: - TIPSPayout Tests
    
    @Test func testTIPSPayoutInitialization() throws {
        let payoutDate = Date()
        let accountId = UUID()
        let payout = TIPSPayout(
            cusip: "912810FD5",
            date: payoutDate,
            accountId: accountId,
            accountName: "Test Account",
            amountPerBond: 25.50,
            count: 10,
            adjustmentStatus: .adjusted,
            indexRatio: 1.05,
            interestRate: 0.0125,
            includesPrincipal: false
        )
        
        #expect(payout.cusip == "912810FD5")
        #expect(payout.date == payoutDate)
        #expect(payout.amountPerBond == 25.50)
        #expect(payout.amountPer == 25.50)
        #expect(payout.payoutType == .definitive)
    }
    
    @Test func testTIPSPayoutTypes() throws {
        let accountId = UUID()
        let definitivePayout = TIPSPayout(
            cusip: "912810FD5",
            date: Date(),
            accountId: accountId,
            accountName: "Test Account",
            amountPerBond: 25.50,
            count: 10,
            adjustmentStatus: .adjusted,
            indexRatio: 1.05,
            interestRate: 0.0125,
            includesPrincipal: false
        )
        
        let estimatedPayout = TIPSPayout(
            cusip: "912810FH6",
            date: Date(),
            accountId: accountId,
            accountName: "Test Account",
            amountPerBond: 30.75,
            count: 10,
            adjustmentStatus: .unadjusted,
            indexRatio: nil,
            interestRate: 0.0150,
            includesPrincipal: false
        )
        
        #expect(definitivePayout.payoutType == .definitive)
        #expect(estimatedPayout.payoutType == .definitive)
        #expect(definitivePayout.adjustmentStatus == .adjusted)
        #expect(estimatedPayout.adjustmentStatus == .unadjusted)
    }
    
    @Test func testTIPSPayoutMutability() throws {
        let accountId = UUID()
        var payout = TIPSPayout(
            cusip: "912810FD5",
            date: Date(),
            accountId: accountId,
            accountName: "Test Account",
            amountPerBond: 25.50,
            count: 10,
            adjustmentStatus: .adjusted,
            indexRatio: 1.05,
            interestRate: 0.0125,
            includesPrincipal: false
        )
        
        let newDate = Date().addingTimeInterval(86400) // +1 day
        payout.date = newDate
        payout.amountPerBond = 30.00
        
        #expect(payout.date == newDate)
        #expect(payout.amountPerBond == 30.00)
        #expect(payout.amountPer == 30.00)
    }
} 