//
//  LoginCredentials.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation

class LoginCredentials{
  var email : String;
  var password : String;
  
  init(email : String, password : String){
    self.email = email
    self.password = password
  }
}
