//
//  ServletResponse.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/6/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation
import SwiftyJSON


class ServletResponse : NSObject
{
  var success : Bool
  var errorMessage : String
  
  init(success : Bool){
    self.success = success
    errorMessage = ""
  }
  
  init(success : Bool, errorMessage : String){
    self.success = success
    self.errorMessage = errorMessage
  }

  init(errorMessage : String){
    self.success = false
    self.errorMessage = errorMessage
  }
  
  init(json : JSON){
    self.success = json["success"].boolValue
    self.errorMessage = json["errorMessage"].stringValue
  }
}
