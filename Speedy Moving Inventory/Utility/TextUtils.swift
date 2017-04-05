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
  
  static func isBlank(s : String) -> Bool{
  
    var trimmed = s.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
    return trimmed.characters.count == 0;
    
  }
  
  static func formSingleLineAddress(address : Address) -> String{
    var line2 = ", "
    if address.addressLine2 != nil{
      if !isBlank(s: address.addressLine2!){
        line2 = " " + address.addressLine2! + ", "
      }
    }
    var result = address.street! + line2 + address.city!;
    result = result + ", " + address.state! + " " + address.zip!;
    return result;
    
  }
  
  static func formFt3Superscript( text : String) -> NSAttributedString{
    
    //let ranges = text.indexes(of: "ft3");
    //let range = ranges[ranges.count - 1 ];
    
    
    let string = NSString(string: text)
    var range = string.range(of: "ft3")
    range.location += 2;
    range.length = 1;
    
    let font = UIFont.systemFont(ofSize:17)
    let fontSuper = UIFont.systemFont(ofSize:9)
    let attString:NSMutableAttributedString =
      NSMutableAttributedString(string: text, attributes: [NSFontAttributeName:font])
    
    attString.setAttributes([NSFontAttributeName:fontSuper, NSBaselineOffsetAttributeName:5],
                            range: range);
    return attString;
    
    /*
     var ranges = text.ranges(of: "3");
     var targetRange = ranges[ranges.count -1]
     let startIndex =
     let index = text.startIndex.distance(indexes[indexes.count-1]);
     let intIndex = text.distance(from: text.startIndex, to: index)
     
     
     let attString:NSMutableAttributedString =
     NSMutableAttributedString(string: text, attributes: [NSFontAttributeName:font])
     attString.setAttributes([NSFontAttributeName:fontSuper,NSBaselineOffsetAttributeName:4],
     range: NSRange(location: intIndex,length:1))
     
     
     return attString;
     */
  }

}
