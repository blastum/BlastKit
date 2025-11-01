//
//  TIPSPayout.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/2/25.
//

import Foundation

/// Represents a payout for a specific CUSIP on a given date.
/// Includes the payout amount per bond and whether it is definitive or estimated.
public struct TIPSPayout {
    public enum AdjustmentStatus {
        case adjusted      // Index ratio available and applied
        case unadjusted   // Index ratio not available, using last known value
    }

    public enum PayoutType {
        case definitive
        case estimated
    }

    public var cusip: String
    public var date: Date
    public var accountId: UUID           // Reference to TIPSAccount.id
    public var accountName: String       // Reference to TIPSAccount.name
    public var amountPerBond: Double
    public var count: Int
    public var totalAmount: Double { amountPerBond * Double(count) }
    public var adjustmentStatus: AdjustmentStatus
    public var indexRatio: Double?  // Nil if unadjusted
    public var interestRate: Double
    public var includesPrincipal: Bool  // True on maturity date

    // Backward compatibility
    public var amountPer: Double { amountPerBond }
    public var payoutType: PayoutType { .definitive } // Default to definitive for now
}

// MARK: - Aggregation Data Structures

/// Represents aggregated payouts for a specific account on a specific date
public struct AccountPayout {
    public var accountId: UUID
    public var accountName: String
    public var date: Date
    public var totalAmount: Double
    public var adjustedAmount: Double    // Portion with index ratio data
    public var unadjustedAmount: Double  // Portion without index ratio data
    public var payoutCount: Int
    public var payouts: [TIPSPayout]     // Individual payouts for this account on this date

    public init(accountId: UUID, accountName: String, date: Date, payouts: [TIPSPayout]) {
        self.accountId = accountId
        self.accountName = accountName
        self.date = date
        self.payouts = payouts
        self.payoutCount = payouts.count

        var adjusted = 0.0
        var unadjusted = 0.0

        for payout in payouts {
            let amount = payout.totalAmount
            switch payout.adjustmentStatus {
            case .adjusted:
                adjusted += amount
            case .unadjusted:
                unadjusted += amount
            }
        }

        self.adjustedAmount = adjusted
        self.unadjustedAmount = unadjusted
        self.totalAmount = adjusted + unadjusted
    }
}

/// Represents aggregated payouts across all accounts on a specific date
public struct AggregatePayout {
    public var date: Date
    public var totalAmount: Double
    public var adjustedAmount: Double    // Portion with index ratio data
    public var unadjustedAmount: Double  // Portion without index ratio data
    public var payoutCount: Int
    public var accountPayouts: [AccountPayout]  // Per-account breakdown for this date
    public var payouts: [TIPSPayout]           // All individual payouts on this date

    public init(date: Date, accountPayouts: [AccountPayout]) {
        self.date = date
        self.accountPayouts = accountPayouts
        self.payouts = accountPayouts.flatMap { $0.payouts }
        self.payoutCount = self.payouts.count

        self.totalAmount = accountPayouts.reduce(0) { $0 + $1.totalAmount }
        self.adjustedAmount = accountPayouts.reduce(0) { $0 + $1.adjustedAmount }
        self.unadjustedAmount = accountPayouts.reduce(0) { $0 + $1.unadjustedAmount }
    }
}

/// Represents the complete payout calendar with per-account and aggregate views
public struct PayoutCalendar {
    public var dateRange: ClosedRange<Date>
    public var aggregatePayouts: [AggregatePayout]  // Sorted by date, includes per-account breakdown
    public var accountCalendars: [UUID: AccountCalendar]  // Per-account calendars keyed by account ID
    public var totalAdjustedAmount: Double
    public var totalUnadjustedAmount: Double

    public init(aggregatePayouts: [AggregatePayout], accountCalendars: [UUID: AccountCalendar]) {
        self.aggregatePayouts = aggregatePayouts.sorted { $0.date < $1.date }
        self.accountCalendars = accountCalendars

        guard let firstDate = self.aggregatePayouts.first?.date,
              let lastDate = self.aggregatePayouts.last?.date else {
            // Empty calendar
            self.dateRange = Date()...Date()
            self.totalAdjustedAmount = 0
            self.totalUnadjustedAmount = 0
            return
        }

        self.dateRange = firstDate...lastDate
        self.totalAdjustedAmount = self.aggregatePayouts.reduce(0) { $0 + $1.adjustedAmount }
        self.totalUnadjustedAmount = self.aggregatePayouts.reduce(0) { $0 + $1.unadjustedAmount }
    }
}

/// Represents a complete payout calendar for a specific account
public struct AccountCalendar {
    public var accountId: UUID
    public var accountName: String
    public var dateRange: ClosedRange<Date>
    public var payouts: [AccountPayout]  // Sorted by date
    public var totalAdjustedAmount: Double
    public var totalUnadjustedAmount: Double

    public init(accountId: UUID, accountName: String, payouts: [AccountPayout]) {
        self.accountId = accountId
        self.accountName = accountName
        self.payouts = payouts.sorted { $0.date < $1.date }

        guard let firstDate = self.payouts.first?.date,
              let lastDate = self.payouts.last?.date else {
            // Empty calendar
            self.dateRange = Date()...Date()
            self.totalAdjustedAmount = 0
            self.totalUnadjustedAmount = 0
            return
        }

        self.dateRange = firstDate...lastDate
        self.totalAdjustedAmount = self.payouts.reduce(0) { $0 + $1.adjustedAmount }
        self.totalUnadjustedAmount = self.payouts.reduce(0) { $0 + $1.unadjustedAmount }
    }
}
