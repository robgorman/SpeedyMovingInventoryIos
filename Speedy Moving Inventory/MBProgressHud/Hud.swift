//
//  Hud.swift
//  dl643
//
//  Created by rob gorman on 2/5/15.
//  Copyright (c) 2015 Direct Linx. All rights reserved.
//

import Foundation
import UIKit


class Hud {
  
  class func on(_ vc : UIViewController)
  {
    
    let hud : MBProgressHUD = MBProgressHUD.showAdded(to: vc.view, animated: true)
    //hud.backgroundColor = UIColor.darkGray
  //  hud.tintColor = UIColor.darkGray
    hud.contentColor = UIColor.darkGray
    //hud.colo
    
    //hud.backgroundColor = UIColor.blue

    //loadingNotification.mode =
    //loadingNotification?.mode = MBProgressHUDModeIndeterminate
  }
  
  class func off(_ vc : UIViewController)
  {
    MBProgressHUD.hideAllHUDs(for: vc.view, animated: true)
  }
}
