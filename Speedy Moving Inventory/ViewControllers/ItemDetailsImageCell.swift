//
//  ItemDetailsImageCell.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/5/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Foundation

import UIKit

class ItemDetailsImageCell : UICollectionViewCell {
  var index : Int!;
  var callback : IItemDeletePressed!
  
  @IBOutlet weak var itemImageView: UIImageView!
  
  @IBOutlet weak var containerView: UIView!
  
  @IBOutlet weak var imageDate: UILabel!
  @IBOutlet weak var deleteButton: UIButton!
  @IBAction func deletePressed(_ sender: Any) {
    callback.deleteItem(index);
  }
}
