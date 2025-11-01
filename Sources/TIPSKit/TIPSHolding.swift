//
//  TIPSLot.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/1/25.
//

import Foundation

// Represents a holding of a specific TIPS security (by CUSIP),
// including the purchase date and the number of bonds owned.
public class TIPSHolding: Equatable {
    public let cusip: String
    public let purchaseDate: Date
    public let count: Int

    public init(cusip: String, purchaseDate: Date, count: Int) {
        self.cusip = cusip
        self.purchaseDate = purchaseDate
        self.count = count
    }
    
    public static func == (lhs: TIPSHolding, rhs: TIPSHolding) -> Bool {
        lhs.cusip == rhs.cusip &&
        lhs.purchaseDate == rhs.purchaseDate &&
        lhs.count == rhs.count
    }
}
