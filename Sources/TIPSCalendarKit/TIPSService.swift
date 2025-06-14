//
//  TIPSService.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/2/25.
//

import FetchKit
import Foundation
import TIPSKit

@available(macOS 12.0, *)
class TIPSService {
    public enum Err: Error {
        case invalidResponse
    }

    private var accounts: [TIPSAccount] = []
    private lazy var service = NetworkService()

    init() {}

    func addAccount(_ account: TIPSAccount) {
        accounts.append(account)
    }

    func cusips() -> Set<String> {
        accounts.reduce(Set<String>()) { result, account in
            result.union(account.cusips)
        }
    }

    func summaries() async -> Result<[String: TIPSSummary], Error> {
        let cusips = cusips()
        let request = TIPSRequest.summary(filters: [.in(._cusip, cusips)],
                                          pageSize: cusips.count)
        return await service.fetch(request).flatMap { result in
            guard case let .summary(summaries) = result else {
                return .failure(Err.invalidResponse)
            }
            return .success(summaries.reduce(into: [String: TIPSSummary]()) { dict, summary in
                dict[summary.cusip] = summary
            })
        }
    }
}
