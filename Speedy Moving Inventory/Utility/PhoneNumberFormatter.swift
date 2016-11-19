//
//  PhoneNumberFormatter.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/27/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation

class PhoneNumberFormatter{
  
  static func format(_ input : String) -> String{
    var formatted = ""
    if input.characters.count == 0{
      return formatted
    }
    var source = rawValue(input)
    // handle leading 1 if it exists
    if source[0] == "1"{
      if source.characters.count > 1{
        source = source[1 ... source.characters.count-1]
      } else {
        source = ""
      }
      
      formatted = "1 "
    }
    
    if source.characters.count <= 2 {
      formatted += "(" + source
    } else if source.characters.count == 3{
      formatted += "(" + source + ")"
    } else if source.characters.count < 6 {
      formatted += "(" + source[0...2] + ") " + source[3...source.characters.count-1]
    }else if source.characters.count == 6 {
      formatted += "(" + source[0...2] + ") " + source[3...source.characters.count-1] + "-"
    } else {
      formatted += "(" + source[0...2] + ") " + source[3...5] + "-" + source[6...source.characters.count-1]
    }
  
    return formatted
  }
  
  static func isDigit(_ s : String) -> Bool {
    return s == "0"
    || s == "1"
    || s == "2"
    || s == "3"
    || s == "4"
    || s == "5"
    || s == "6"
    || s == "7"
    || s == "8"
    || s == "9";
  }
  
  static func rawValue( _ input : String) -> String{
    var result = ""
    if input.characters.count > 0 {
      for  i in 0 ... input.characters.count - 1 {
        let s : String = input[i]
        if isDigit(s){
          result += input[i]
        }
      } 
    }
    
    if result.characters.count == 11 && result[0] == "1" {
      result = result[1 ... result.characters.count - 1]
    }
    return result;
  }
    
    
    
}
