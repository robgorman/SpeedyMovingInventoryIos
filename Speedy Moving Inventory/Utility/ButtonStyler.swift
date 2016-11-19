//
//  ButtonStyler.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/12/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation
import UIKit

class ButtonStyler{
  static func style(_ button : UIButton){
    button.layer.borderWidth = 2.0
    button.layer.borderColor = UIColor.white.cgColor
    button.layer.cornerRadius = 5
    button.clipsToBounds = true

  }
}
