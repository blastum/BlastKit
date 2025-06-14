//
//  URLSessionProtocol.swift
//  FetchKit
//
//  Created by James Blasius on 4/27/25.
//

import Foundation

// MARK: - URLSessionProtocol

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async -> Result<(Data, URLResponse), Error>
}

// MARK: - URLSession + URLSessionProtocol

@available(macOS 12.0, *)
extension URLSession: URLSessionProtocol {
    public func data(for request: URLRequest) async -> Result<(Data, URLResponse), Error> {
        do {
            return try .success(await data(for: request))
        } catch {
            return .failure(error)
        }
    }
}
