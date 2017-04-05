//
//  MovingItemDataDescription.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 11/22/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase

enum Room : String {case Basement, Bedroom,
  Garage, DiningRoom, Den, Office, LivingRoom, Kitchen, Bathroom, Patio,
  Sunroom, Laundry, Nursery, Other
  
  static var allValues: [Room]{
    return [.Basement, .Bedroom,
            .Garage, .DiningRoom, .Den, .Office, .LivingRoom, .Kitchen, .Bathroom, .Patio,
            .Sunroom, .Laundry, .Nursery, .Other];
  }
}

 class MovingItemDataDescription : FirebaseDataObject {
  
  // note xxxInverse fields are just for sorting in reverse order
  
  var room : String?
  var itemName : String?
  var cubicFeet : NSNumber?
  var isBox : NSNumber?;
  var boxSize : String?
  var specialInstructions : String?

  
  
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
   
  }
  
  init(
    room : String,
    itemName: String,
    cubicFeet : Float,
    isBox : Bool,
    boxSize : String,
    specialInstructions : String) {
    
    super.init()
    self.room = room;
    self.itemName = itemName;
    self.setCubicFeet(cubicFeet: cubicFeet);
    self.setIsBox(value : isBox)
    self.boxSize = boxSize;
    self.specialInstructions = specialInstructions;
    
    
  }
  
  func asFirebaseObject() -> [String : Any] {
    var fbo = [String:Any]()
    fbo["room"] = room
    fbo["itemName"] = itemName
    fbo["cubicFeet"] = cubicFeet
    fbo["isBox"] = isBox
    fbo["boxSize"] = boxSize
    fbo["specialInstructions"] = specialInstructions
    
    return fbo;
    
  }
  func getCubicFeet() -> Float {return ((cubicFeet?.floatValue)!)}
  func getIsBox() -> Bool {return (isBox?.boolValue)!}
  
  func setCubicFeet(cubicFeet : Float){
    self.cubicFeet = NSNumber(value : cubicFeet);
  }
  
  func setIsBox(value : Bool){
    self.isBox = NSNumber(value : value);
  }
  
 }
