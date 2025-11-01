//
//  TIPSService.swift
//  TIPSCalLib
//
//  Created by James Blasius on 5/2/25.
//

import FetchKit
import Foundation
import SwiftEase

public class TIPSService {
    public enum Err: Error {
        case invalidResponse
        case missingSummaryData(cusip: String)
        case missingDatedDate(cusip: String)
        case missingMaturityDate(cusip: String)
    }

    private var accounts: [TIPSAccount] = []
    private lazy var service = NetworkService(session: createCachingSession())
    
    /// The NetworkService instance for accessing call statistics
    public var networkService: NetworkService {
        service
    }

    public init(urlCache: URLCache? = nil) {
        if let urlCache = urlCache {
            self.urlCache = urlCache
        }
    }
    
    private var urlCache: URLCache?
    
    private func createCachingSession() -> URLSession {
        let config = URLSessionConfiguration.default
        
        // Configure caching
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // Use provided cache or create new one
        if let urlCache = urlCache {
            config.urlCache = urlCache
        } else {
            // Create default cache (50 MB disk, 10 MB memory)
            // Note: Each TIPSService instance creates its own cache by default.
            // For cross-run persistence, pass a shared URLCache instance to init.
            config.urlCache = URLCache(
                memoryCapacity: 10 * 1024 * 1024,  // 10 MB memory
                diskCapacity: 50 * 1024 * 1024     // 50 MB disk
            )
        }
        
        return URLSession(configuration: config)
    }

    public func addAccount(_ account: TIPSAccount) {
        accounts.append(account)
    }

    public func cusips() -> Set<String> {
        accounts.reduce(Set<String>()) { result, account in
            result.union(account.cusips)
        }
    }

    public func summaries() async -> Result<[String: TIPSSummary], Error> {
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

    // MARK: - Step 3: Payout Date Schedule Generation

    /// Calculate the first payment date for a holding based on purchase date vs dated date
    /// - Parameters:
    ///   - holding: The TIPS holding
    ///   - summary: Summary data for the security
    /// - Returns: The first payment date, or nil if calculation fails
    func firstPaymentDate(for holding: TIPSHolding, summary: TIPSSummary) -> Date? {
        guard let datedDate = summary.datedDate else {
            return nil
        }

        let purchaseDate = holding.purchaseDate

        // If purchase date is before dated date → first payment is after dated date
        if purchaseDate.isBefore(datedDate) {
            return datedDate.nextSemiAnnualPaymentDate(from: datedDate)
        }

        // If purchase date is after dated date → first payment is next payment date after purchase
        return purchaseDate.nextSemiAnnualPaymentDate(from: datedDate)
    }

    /// Generate all payout dates for a holding from first payment to maturity
    /// - Parameters:
    ///   - holding: The TIPS holding
    ///   - summary: Summary data for the security
    /// - Returns: Array of payout dates including maturity date
    func payoutDates(for holding: TIPSHolding, summary: TIPSSummary) throws -> [Date] {
        guard let maturityDate = summary.maturityDate else {
            throw Err.missingMaturityDate(cusip: holding.cusip)
        }

        guard let firstPaymentDate = firstPaymentDate(for: holding, summary: summary) else {
            throw Err.missingDatedDate(cusip: holding.cusip)
        }

        // Generate semi-annual payment dates from first payment to maturity
        let paymentDates = Date.semiAnnualPaymentDates(from: firstPaymentDate, to: maturityDate, referenceDate: summary.datedDate ?? firstPaymentDate)

        // Ensure maturity date is included if not already in the list
        if !paymentDates.contains(where: { $0.isSameDay(as: maturityDate) }) {
            return paymentDates + [maturityDate]
        }

        return paymentDates.sorted()
    }

    /// Generate payout schedules for all holdings across all accounts
    /// - Parameter summaries: Dictionary of CUSIP -> TIPSSummary
    /// - Returns: Dictionary of CUSIP -> Array of payout dates
    public func payoutSchedules(summaries: [String: TIPSSummary]) -> Result<[String: [Date]], Error> {
        var schedules: [String: [Date]] = [:]

        for account in accounts {
            for holding in account.holdings {
                guard let summary = summaries[holding.cusip] else {
                    return .failure(Err.missingSummaryData(cusip: holding.cusip))
                }

                do {
                    let dates = try payoutDates(for: holding, summary: summary)
                    schedules[holding.cusip] = dates
                } catch {
                    return .failure(error)
                }
            }
        }

        return .success(schedules)
    }

    // MARK: - Step 4: Index Ratio Data Fetching

    /// Fetch index ratio data for all CUSIPs organized by date
    /// - Parameter payoutSchedules: Dictionary of CUSIP -> Array of payout dates (from step 3)
    /// - Returns: Dictionary of CUSIP -> Date -> TIPSDetail
    public func indexRatios(payoutSchedules: [String: [Date]]) async -> Result<[String: [Date: TIPSDetail]], Error> {
        guard !payoutSchedules.isEmpty else {
            return .success([:])
        }

        // Optimized: fetch all CUSIPs and dates in a single API call
        let batchResult = await fetchDetailsBatch(payoutSchedules: payoutSchedules)
        return batchResult
    }

    /// Fetch index ratio data for all CUSIPs organized by date (legacy method for backward compatibility)
    /// - Parameter lookaheadYears: Number of years beyond current date to fetch data for (default: 2)
    /// - Returns: Dictionary of CUSIP -> Date -> TIPSDetail
    @available(*, deprecated, message: "Use indexRatios(payoutSchedules:) instead for better performance")
    func indexRatios(lookaheadYears: Int = 2) async -> Result<[String: [Date: TIPSDetail]], Error> {
        let cusips = cusips()
        guard !cusips.isEmpty else {
            return .success([:])
        }

        // Determine date ranges for each CUSIP
        let dateRanges = await dateRangesForCUSIPs(cusips, lookaheadYears: lookaheadYears)

        // Fetch detail data for each CUSIP
        var allDetails: [String: [Date: TIPSDetail]] = [:]

        for cusip in cusips {
            guard let dateRange = dateRanges[cusip] else {
                continue // Skip CUSIPs without valid date ranges
            }

            let detailsResult = await fetchDetails(for: cusip, in: dateRange)
            switch detailsResult {
            case .success(let details):
                allDetails[cusip] = details
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(allDetails)
    }

    /// Determine the date range for each CUSIP based on holdings
    /// - Parameters:
    ///   - cusips: Set of CUSIPs to get date ranges for
    ///   - lookaheadYears: Years beyond current date to include for future data
    /// - Returns: Dictionary of CUSIP -> date range
    private func dateRangesForCUSIPs(_ cusips: Set<String>, lookaheadYears: Int) async -> [String: ClosedRange<Date>] {
        let currentDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: lookaheadYears, to: currentDate)!

        var dateRanges: [String: ClosedRange<Date>] = [:]

        for cusip in cusips {
            // Find all holdings for this CUSIP across all accounts
            var earliestPurchase: Date? = nil

            for account in accounts {
                for holding in account.holdings where holding.cusip == cusip {
                    if earliestPurchase == nil || holding.purchaseDate.isBefore(earliestPurchase!) {
                        earliestPurchase = holding.purchaseDate
                    }
                    // Note: We don't have maturity date here - we'll need to get it from summary data
                    // For now, use current date + lookahead as fallback
                }
            }

            if let earliestPurchase = earliestPurchase {
                // Start from earliest purchase date, end at current date + lookahead
                dateRanges[cusip] = earliestPurchase...endDate
            }
        }

        return dateRanges
    }

    /// Fetch detail data for all CUSIPs and dates in a single optimized batch request
    /// - Parameter payoutSchedules: Dictionary of CUSIP -> Array of payout dates
    /// - Returns: Dictionary of CUSIP -> Date -> TIPSDetail
    private func fetchDetailsBatch(payoutSchedules: [String: [Date]]) async -> Result<[String: [Date: TIPSDetail]], Error> {
        // Collect all unique dates and CUSIPs
        var allDates = Set<String>()
        let cusips = Array(payoutSchedules.keys)
        
        for dates in payoutSchedules.values {
            for date in dates {
                allDates.insert(DateFormatter.iso8601.string(from: date))
            }
        }
        
        // Create filters for all CUSIPs and all dates
        let filters: [Filter<TIPSDetail.CodingKeys>] = [
            .in(._cusip, cusips),
            .in(._indexRatioDate, Array(allDates))
        ]
        
        // Sort by date and CUSIP for consistent results
        let sort: [Sort<TIPSDetail.CodingKeys>] = [.asc(._cusip), .asc(._indexRatioDate)]
        
        // Request all data in one call
        let request = TIPSRequest.detail(
            filters: filters,
            sort: sort,
            pageSize: nil, // Let API return all results
            pageNumber: 1
        )
        
        let result = await service.fetch(request)
        
        switch result {
        case .success(let response):
            guard case let .detail(details) = response else {
                return .failure(Err.invalidResponse)
            }
            
            // Organize by CUSIP -> Date
            var allDetails: [String: [Date: TIPSDetail]] = [:]
            for detail in details {
                guard let date = detail.indexRatioDate else { continue }
                
                if allDetails[detail.cusip] == nil {
                    allDetails[detail.cusip] = [:]
                }
                allDetails[detail.cusip]?[date] = detail
            }
            
            return .success(allDetails)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Fetch TIPS detail data for a specific CUSIP on specific dates (optimized)
    /// - Parameters:
    ///   - cusip: The CUSIP to fetch data for
    ///   - payoutDates: The specific dates to fetch data for
    /// - Returns: Dictionary of Date -> TIPSDetail for this CUSIP
    private func fetchDetails(for cusip: String, on payoutDates: [Date]) async -> Result<[Date: TIPSDetail], Error> {
        // Convert dates to ISO8601 strings for API filtering
        let dateStrings = payoutDates.map { DateFormatter.iso8601.string(from: $0) }

        // Create filters for CUSIP and specific dates
        let filters: [Filter<TIPSDetail.CodingKeys>] = [
            .equal(._cusip, cusip),
            .in(._indexRatioDate, dateStrings)
        ]

        // Sort by date ascending
        let sort: [Sort<TIPSDetail.CodingKeys>] = [.asc(._indexRatioDate)]

        // Single request should suffice since we're filtering by specific dates
        let request = TIPSRequest.detail(
            filters: filters,
            sort: sort,
            pageSize: dateStrings.count, // Request exactly the number of dates we need
            pageNumber: 1
        )

        let result = await service.fetch(request)

        switch result {
        case .success(let response):
            guard case let .detail(details) = response else {
                return .failure(Err.invalidResponse)
            }

            // Organize by date
            var detailsByDate: [Date: TIPSDetail] = [:]
            for detail in details {
                if let date = detail.indexRatioDate {
                    detailsByDate[date] = detail
                }
            }

            return .success(detailsByDate)

        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Step 5: Payout Calculation

    /// Calculate all payouts for a specific holding across all payout dates
    /// - Parameters:
    ///   - holding: The TIPS holding
    ///   - account: The account containing this holding
    ///   - summary: Summary data for the security
    ///   - payoutDates: All payout dates for this holding
    ///   - indexRatios: Available index ratio data organized by date
    /// - Returns: Array of TIPSPayout records
    public func calculatePayouts(
        for holding: TIPSHolding,
        account: TIPSAccount,
        summary: TIPSSummary,
        payoutDates: [Date],
        indexRatios: [Date: TIPSDetail]
    ) -> [TIPSPayout] {
        guard let interestRate = summary.interestRate else {
            // Cannot calculate payouts without interest rate
            return []
        }

        let faceValue: Double = 1000.0 // Standard TIPS face value
        var lastKnownIndexRatio: Double? = nil
        var payouts: [TIPSPayout] = []

        for date in payoutDates {
            // Determine if this is the maturity date (includes principal)
            let isMaturityDate = summary.maturityDate?.isSameDay(as: date) ?? false

            // Get index ratio for this date, or use last known
            let tipsDetail = indexRatios[date]
            let indexRatio = tipsDetail?.dailyIndexRatio ?? lastKnownIndexRatio
            let adjustmentStatus: TIPSPayout.AdjustmentStatus = (tipsDetail != nil) ? .adjusted : .unadjusted

            // Update last known index ratio if we have one
            if let currentRatio = tipsDetail?.dailyIndexRatio {
                lastKnownIndexRatio = currentRatio
            }

            // Calculate adjusted principal
            let adjustedPrincipal = faceValue * (indexRatio ?? 1.0) // Use 1.0 (face value) if no index ratio ever available

            // Calculate interest payment (semi-annual)
            let interestPayment = (adjustedPrincipal * interestRate) / 2.0

            // Calculate total payout per bond
            let totalPayoutPerBond = isMaturityDate ?
                (interestPayment + adjustedPrincipal) : // Maturity: interest + principal
                interestPayment // Regular payment: interest only

            let payout = TIPSPayout(
                cusip: holding.cusip,
                date: date,
                accountId: account.id,
                accountName: account.name,
                amountPerBond: totalPayoutPerBond,
                count: holding.count,
                adjustmentStatus: adjustmentStatus,
                indexRatio: indexRatio,
                interestRate: interestRate,
                includesPrincipal: isMaturityDate
            )

            payouts.append(payout)
        }

        return payouts
    }

    /// Calculate payouts for all holdings across all accounts
    /// - Parameters:
    ///   - summaries: Dictionary of CUSIP -> TIPSSummary
    ///   - payoutSchedules: Dictionary of CUSIP -> Array of payout dates
    ///   - indexRatios: Dictionary of CUSIP -> Date -> TIPSDetail
    /// - Returns: Array of all TIPSPayout records
    public func calculateAllPayouts(
        summaries: [String: TIPSSummary],
        payoutSchedules: [String: [Date]],
        indexRatios: [String: [Date: TIPSDetail]]
    ) -> [TIPSPayout] {
        var allPayouts: [TIPSPayout] = []

        for account in accounts {
            for holding in account.holdings {
                guard let summary = summaries[holding.cusip],
                      let payoutDates = payoutSchedules[holding.cusip] else {
                    continue // Skip if missing required data
                }

                // Use available index ratios for this CUSIP, or empty dict if none available
                let cusipIndexRatios = indexRatios[holding.cusip] ?? [:]

                let holdingPayouts = calculatePayouts(
                    for: holding,
                    account: account,
                    summary: summary,
                    payoutDates: payoutDates,
                    indexRatios: cusipIndexRatios
                )

                allPayouts.append(contentsOf: holdingPayouts)
            }
        }

        return allPayouts.sorted { $0.date < $1.date }
    }

    /// Fetch TIPS detail data for a specific CUSIP within a date range (legacy method)
    /// - Parameters:
    ///   - cusip: The CUSIP to fetch data for
    ///   - dateRange: The date range to fetch data for
    /// - Returns: Dictionary of Date -> TIPSDetail for this CUSIP
    private func fetchDetails(for cusip: String, in dateRange: ClosedRange<Date>) async -> Result<[Date: TIPSDetail], Error> {
        // For now, let's fetch all data for the CUSIP and filter client-side
        // The API seems to have issues with date filtering
        let filters: [Filter<TIPSDetail.CodingKeys>] = [
            .equal(._cusip, cusip)
        ]

        // Sort by date ascending
        let sort: [Sort<TIPSDetail.CodingKeys>] = [.asc(._indexRatioDate)]

        var allDetails: [TIPSDetail] = []
        var pageNumber = 1
        let pageSize = 100 // Treasury API default page size

        // Fetch all pages
        while true {
            let request = TIPSRequest.detail(
                filters: filters,
                sort: sort,
                pageSize: pageSize,
                pageNumber: pageNumber
            )

            let result = await service.fetch(request)

            switch result {
            case .success(let response):
                guard case let .detail(details) = response else {
                    return .failure(Err.invalidResponse)
                }

                allDetails.append(contentsOf: details)

                // If we got less than pageSize results, we've reached the end
                if details.count < pageSize {
                    break
                }

                pageNumber += 1

                // Safety check: don't fetch more than 1000 pages to prevent infinite loops
                if pageNumber > 1000 {
                    break
                }

            case .failure(let error):
                // If we get a failure on page 1, that's an error
                // But if we get a failure on a later page, it might just mean we've reached the end
                if pageNumber == 1 {
                    return .failure(error)
                } else {
                    // Assume we've reached the end of available data
                    break
                }
            }
        }

        // Filter by date range client-side and organize by date
        var detailsByDate: [Date: TIPSDetail] = [:]
        for detail in allDetails {
            if let date = detail.indexRatioDate,
               dateRange.contains(date) {
                detailsByDate[date] = detail
            }
        }

        return .success(detailsByDate)
    }

    // MARK: - Step 6: Aggregate Payouts

    /// Aggregate all payouts into per-account and aggregate calendar views
    /// - Parameter payouts: All individual TIPSPayout records
    /// - Returns: Complete PayoutCalendar with per-account and aggregate data
    public func aggregatePayouts(_ payouts: [TIPSPayout]) -> PayoutCalendar {
        // Group payouts by date first
        let payoutsByDate = Dictionary(grouping: payouts) { $0.date }

        // Create account calendars
        var accountCalendars: [UUID: AccountCalendar] = [:]

        // Create per-account calendars
        for account in accounts {
            let accountPayouts: [AccountPayout] = payoutsByDate.keys.sorted().compactMap { date in
                let datePayouts = payoutsByDate[date] ?? []
                let accountDatePayouts = datePayouts.filter { $0.accountId == account.id }
                guard !accountDatePayouts.isEmpty else { return nil }
                return AccountPayout(accountId: account.id, accountName: account.name, date: date, payouts: accountDatePayouts)
            }

            let accountCalendar = AccountCalendar(accountId: account.id, accountName: account.name, payouts: accountPayouts)
            accountCalendars[account.id] = accountCalendar
        }

        // Create aggregate payouts for each date
        let aggregatePayouts: [AggregatePayout] = payoutsByDate.keys.sorted().map { date in
            let datePayouts = payoutsByDate[date] ?? []
            let accountPayouts: [AccountPayout] = accounts.compactMap { account in
                let accountDatePayouts = datePayouts.filter { $0.accountId == account.id }
                guard !accountDatePayouts.isEmpty else { return nil }
                return AccountPayout(accountId: account.id, accountName: account.name, date: date, payouts: accountDatePayouts)
            }

            return AggregatePayout(date: date, accountPayouts: accountPayouts)
        }

        return PayoutCalendar(aggregatePayouts: aggregatePayouts, accountCalendars: accountCalendars)
    }
}
