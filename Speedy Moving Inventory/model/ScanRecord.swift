//
//  ScanRecord.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 2/1/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase

class ScanRecord : FirebaseDataObject {
  
  var scanDateTime : NSNumber?
  var latitude : NSNumber?
  var longitude : NSNumber?
  var uidOfScanner : String?
  var isScanOverride : NSNumber?
  var lifecycle : String?
  
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
    }
  
  init(
    scanDateTime: Date,
    latitude : Double,
    longitude : Double,
    uidOfScanner : String,
    isScanOverride : Bool,
    lifecycle : Lifecycle)
    {
    
      super.init()
      self.setScanDateTime(value : scanDateTime)
      self.setLatitude(value: latitude)
      self.setLongitude(value : longitude)
      self.uidOfScanner = uidOfScanner
      self.setIsScanOverride(value: isScanOverride)
      self.lifecycle = lifecycle.rawValue
      
    
    
    
    }
  
  func asFirebaseObject() -> [String : Any] {
    var fbo = [String:Any]()
    fbo["scanDateTime"] = scanDateTime
    fbo["latitude"] = latitude
    fbo["longitude"] = longitude
    fbo["uidOfScanner"] = uidOfScanner
    fbo["isScanOverride"] = isScanOverride
    fbo["lifecycle"] = lifecycle
    
    
    return fbo;
    
  }
  
  func getScanDateTime() -> Date{
    return Utility.convertNsNumberToDate(rawValue: scanDateTime);
  }
  func getLatitude() -> Double{
    return (latitude?.doubleValue)!
  }
  func getLongitude() -> Double {
    return (longitude?.doubleValue)!
  }
  func getIsScanOverride() -> Bool {
    return (isScanOverride?.boolValue)!
  }
  
  func setScanDateTime(value : Date){
    let convertedDate = Utility.convertDateToNsNumber(date: value);
    self.scanDateTime = convertedDate;
  }
  func setLatitude(value : Double){
    self.latitude = NSNumber(value : value);
  }
  func setLongitude(value : Double){
    self.longitude = NSNumber(value : value);
  }
  func setIsScanOverride(value : Bool){
    self.isScanOverride = NSNumber(value : value)
  }
  
  

  

}
