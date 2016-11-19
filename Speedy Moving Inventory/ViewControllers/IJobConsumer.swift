//
//  IJobConsumer.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/1/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation


public protocol IJobConsumer : NSObjectProtocol {
  func jobUpdate(_ job : Job)
}
