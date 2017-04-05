//
//  ItemCollectionCell.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation

import UIKit

protocol IItemDeletePressed {
  func deleteItem(_ indexPath : Int);
}

class ItemCollectionCell : UICollectionViewCell {
  
  var index : Int!;
  var callback : IItemDeletePressed!
  
  
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var itemImageView: UIImageView!
  
  @IBOutlet weak var imageDamageWarning: UIImageView!

  @IBOutlet weak var moreImagesLabel: UILabel!
  @IBOutlet weak var imageCheckMark: UIImageView!
  @IBOutlet weak var itemDescription: UILabel!
  @IBOutlet weak var sortLabel: UILabel!
 
  @IBOutlet weak var deleteButton: UIButton!
  @IBAction func deletePressed(_ sender: Any) {
    callback.deleteItem(index);
  }
}
