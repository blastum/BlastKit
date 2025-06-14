//
//  TIPSLot.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/1/25.
//

import Foundation
import TIPSKit

// Represents a holding of a specific TIPS security (by CUSIP),
// including the purchase date and the number of bonds owned.
class TIPSHolding {
    let cusip: String
    let purchaseDate: Date
    let count: Int

    init(cusip: String, purchaseDate: Date, count: Int) {
        self.cusip = cusip
        self.purchaseDate = purchaseDate
        self.count = count
    }
}
