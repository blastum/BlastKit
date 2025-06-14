//
//  TIPSResponse.swift
//  TIPSKit
//
//  Created by James Blasius on 4/29/25.
//

import Foundation

@available(macOS 12.0, *)
public enum TIPSResponse {
    case summary([TIPSSummary])
    case detail([TIPSDetail])
}
