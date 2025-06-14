//
//  SequenceExtensions.swift
//  TIPSCalendarLib
//
//  Created by James Blasius on 5/3/25.
//

import Foundation

extension Sequence where Element: Hashable {
    public func toSet() -> Set<Element> {
        Set(self)
    }

    public func toArray() -> [Element] {
        Array(self)
    }
}
