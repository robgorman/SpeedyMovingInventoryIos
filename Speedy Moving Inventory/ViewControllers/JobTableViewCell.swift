//
//  JobCell.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//


import UIKit

class JobTableViewCell : UITableViewCell {
  
  @IBOutlet weak var labelJobNumber: UILabel!
  
  @IBOutlet weak var labelJobName: UILabel!
  
  
  @IBOutlet weak var imageViewLifecycle: UIImageView!
  @IBOutlet weak var labelPickupDate: UILabel!
  
  @IBOutlet weak var labelEstimatedDelivery: UILabel!
  
  
  override init(style: UITableViewCellStyle,
       reuseIdentifier: String?){
    super.init(style: style, reuseIdentifier: reuseIdentifier);
    
    if (labelJobNumber == nil){
      print("no hookup");
    }
  
  }
  
  required init?( coder: NSCoder){
    super.init(coder : coder)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
