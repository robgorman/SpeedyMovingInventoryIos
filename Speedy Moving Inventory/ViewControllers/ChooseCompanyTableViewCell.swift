//
//  ChooseCompanyTableViewCell.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 1/2/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import Foundation

import UIKit

class ChooseCompanyTableViewCell : UITableViewCell {
  
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var phone: UILabel!
  @IBOutlet weak var contact: UILabel!
  
  required init?( coder: NSCoder){
    super.init(coder : coder)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  
  
}
