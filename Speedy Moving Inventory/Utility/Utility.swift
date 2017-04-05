//
//  Utility.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/3/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

class Utility{
  
  
  class func isQrcCodeValid(code : String) -> Bool{
    // valid QRC codes are UUIDS 216687b2-3c9b-4b71-8cb8-75a775af43b8
  
    // use the UUID class to validate
    let uuid = NSUUID(uuidString: code)
    
    return uuid != nil
  }
  
  class func convertDateToNsNumber(date : Date) -> NSNumber{
   // need to convert the swift date into int64 then multiply by 1000
    // to get the right units for unix timestamp. Not exactly sure why
    // this is correct but it is. There might be a better way too.

    let left = Int64(date.timeIntervalSince1970)
    let convertedDateTime = (left * 1000) as Int64;
    return convertedDateTime as NSNumber
  }
  
  class func convertNsNumberToDate(rawValue : NSNumber?) -> Date{
    let d = (rawValue?.int64Value)!/1000
    let date = Date(timeIntervalSince1970: Double(d))
    return date
  }
  
  class func delay(delaySeconds: Double, closure: @escaping ()->()) {

    let delayTime = DispatchTime.now() + delaySeconds
    DispatchQueue.main.asyncAfter(deadline: delayTime){
      closure()
    }
  }
  
  
  class func playSound(file : String, type : String){
    var soundURL: NSURL?
    var soundID: SystemSoundID = 0
    let filePath = Bundle.main.path(forResource: file, ofType: type)
    soundURL = NSURL(fileURLWithPath: filePath!)
    if let url = soundURL {
      AudioServicesCreateSystemSoundID(url, &soundID)
      AudioServicesPlaySystemSound(soundID)
    }
  }

  class func monetaryValueFromWeight(weight : Float) -> Float{
    let monetaryValue = 0.60 * weight
    return monetaryValue
  }
  
}
