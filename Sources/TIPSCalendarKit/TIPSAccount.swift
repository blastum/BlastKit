//
//  TIPSHoldings.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/1/25.
//

import Foundation
import TIPSKit

class TIPSAccount {
    let name: String
    let holdings: [TIPSHolding]
    let id = UUID()

    init(name: String, holdings: [TIPSHolding]) {
        self.name = name
        self.holdings = holdings
    }
}

extension TIPSAccount {
    var cusips: Set<String> {
        holdings.map(\.cusip).toSet()
    }
}
