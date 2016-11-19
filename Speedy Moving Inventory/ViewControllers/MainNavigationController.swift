//
//  MainNavigationController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MainNavigationController : UINavigationController{
  
  override func viewDidLoad(){
    super.viewDidLoad()
   
        
    FIRAuth.auth()?.addStateDidChangeListener({auth, user in
      if user != nil {
        // someone is logged in, nothing to do
      } else {
        // logout occurred
        // pop th stack and present login
        self.popToRootViewController(animated: true)
        
      }
    })
 
  }
  
}
