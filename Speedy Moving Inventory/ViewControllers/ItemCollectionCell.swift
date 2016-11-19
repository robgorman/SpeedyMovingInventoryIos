//
//  ItemCollectionCell.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation

import UIKit

class ItemCollectionCell : UICollectionViewCell {
  
  @IBOutlet weak var itemImageView: UIImageView!
  
  @IBOutlet weak var imageDamageWarning: UIImageView!

  @IBOutlet weak var imageCheckMark: UIImageView!
  @IBOutlet weak var itemDescription: UILabel!
  @IBOutlet weak var sortLabel: UILabel!
}
