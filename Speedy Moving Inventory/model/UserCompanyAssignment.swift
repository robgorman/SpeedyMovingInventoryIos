//
//  UserCompanyAssignment.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 1/1/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UserCompanyAssignment : FirebaseDataObject  {
  
  var uid : String?
  var companyKey : String?
  var role : String?
  var isDisabled : NSNumber?
  var customerJobKey : String?  // null unless role is customer
  
   
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
  
  func getIsDisabled() -> Bool {
    if (isDisabled == nil){
      isDisabled = NSNumber(value : false);
    }
    return (isDisabled?.boolValue)!
  }
  func getRole() -> Role{
    let role = Role(rawValue: self.role!);
    return role!
  }

}
