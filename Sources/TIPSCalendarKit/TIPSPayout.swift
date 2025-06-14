//
//  TIPSPayout.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/2/25.
//

import Foundation
import TIPSKit

/// Represents a payout for a specific CUSIP on a given date.
/// Includes the payout amount per bond and whether it is definitive or estimated.
public struct TIPSPayout {
    public enum PayoutType {
        case definitive
        case estimated
    }
    public var cusip: String
    public var date: Date
    public var amountPer: Double
    public var payoutType: PayoutType
}
