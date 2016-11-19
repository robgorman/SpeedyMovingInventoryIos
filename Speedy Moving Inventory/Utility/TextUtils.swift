//
//  TextUtils.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/12/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation

class TextUtils{
  
  static func isEmpty(_ s : String) -> Bool{
    if s.characters.count == 0 {
      return true
    }
    return false
  }
  
  static func formatPhoneNumber(_ phoneNumber : String) -> String{
    // TODO
    return phoneNumber
  }
  
  static func isPasswordValid(_ password : String) -> Bool{
    if password.characters.count >= minimumPasswordLength(){
      return true
    }
    return false
  }
  
  static func minimumPasswordLength() -> Int{
    return 8
  }
  
  static func containsOnlyDigits(_ s : String) -> Bool {
   
    for ch in s.characters{
      if !(ch == Character("0")
        || ch == Character("1")
        || ch == Character("2")
        || ch == Character("3")
        || ch == Character("4")
        || ch == Character("5")
        || ch == Character("6")
        || ch == Character("7")
        || ch == Character("8")
        || ch == Character("9")){
          return false;
      }
    }
    return true
  }
  
  static func isValidEmail(email : String) -> Bool {
    let pattern: String = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$";
    
    let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    return regex.firstMatch(in: email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
  }
  
  static func isValidCellNumber(_ cellNumber : String) -> Bool{
    if !containsOnlyDigits(cellNumber){
      return false;
    }
    
    if (cellNumber.characters.count != 10){
      return false;
    }
    
    return true;
    
  }
}
