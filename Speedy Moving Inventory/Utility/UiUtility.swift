//
//  UiUtility.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/14/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation
import UIKit

class UiUtility{
  
  static func showAlert(_ title : String, message:String, presenter : UIViewController){
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let defaultAction = UIAlertAction(title:"OK", style: .default, handler:nil)
    alertController.addAction(defaultAction)
    presenter.present(alertController, animated: true, completion: nil)

  }
  static func showAlertWithDismissAction(_ title : String, message:String, presenter : UIViewController,
                        dismiss:@escaping (UIAlertAction) ->Void){
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let defaultAction = UIAlertAction(title:"OK", style: .default, handler:dismiss)
    alertController.addAction(defaultAction)
    presenter.present(alertController, animated: true, completion: nil)
    
  }
  
}
