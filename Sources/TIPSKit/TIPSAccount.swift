//
//  TIPSHoldings.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/1/25.
//

import Foundation
import SwiftEase

public class TIPSAccount {
    public let name: String
    public let holdings: [TIPSHolding]
    public let id = UUID()

    public init(name: String, holdings: [TIPSHolding]) {
        self.name = name
        self.holdings = holdings
    }
}

extension TIPSAccount {
    public var cusips: Set<String> {
        holdings.map(\.cusip).toSet()
    }
}
