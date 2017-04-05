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
  func index(of string: String, options: String.CompareOptions = .literal) -> String.Index? {
    return range(of: string, options: options, range: nil, locale: nil)?.lowerBound
  }
  func indexes(of string: String, options: String.CompareOptions = .literal) -> [String.Index] {
    var result: [String.Index] = []
    var start = startIndex
    while let range = range(of: string, options: options, range: start..<endIndex, locale: nil) {
      result.append(range.lowerBound)
      start = range.upperBound
    }
    return result
  }
  func ranges(of string: String, options: String.CompareOptions = .literal) -> [Range<String.Index>] {
    var result: [Range<String.Index>] = []
    var start = startIndex
    while let range = range(of: string, options: options, range: start..<endIndex, locale: nil) {
      result.append(range)
      start = range.upperBound
    }
    return result
  }
}
