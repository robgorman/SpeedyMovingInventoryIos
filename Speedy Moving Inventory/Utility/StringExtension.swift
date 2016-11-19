//
//  StringExtension.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/27/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation
extension String {
  subscript(i: Int) -> String {
    guard i >= 0 && i < characters.count else { return "" }
    return String(self[index(startIndex, offsetBy: i)])
  }
  subscript(range: Range<Int>) -> String {
    let lowerIndex = index(startIndex, offsetBy: max(0,range.lowerBound), limitedBy: endIndex) ?? endIndex
    return substring(with: lowerIndex..<(index(lowerIndex, offsetBy: range.upperBound - range.lowerBound, limitedBy: endIndex) ?? endIndex))
  }
  subscript(range: ClosedRange<Int>) -> String {
    let lowerIndex = index(startIndex, offsetBy: max(0,range.lowerBound), limitedBy: endIndex) ?? endIndex
    return substring(with: lowerIndex..<(index(lowerIndex, offsetBy: range.upperBound - range.lowerBound + 1, limitedBy: endIndex) ?? endIndex))
  }
}
