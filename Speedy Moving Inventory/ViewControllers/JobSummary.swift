//
//  JobSummary.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class JobSummary : UIViewController, IJobConsumer{
  

  @IBOutlet weak var pickupDateTime  : UILabel! 
  @IBOutlet weak var pickupAddressLine1  : UILabel! 
  @IBOutlet weak var pickupAddressLine2  : UILabel! 
  @IBOutlet weak var pickupAddressLine3  : UILabel! 
  
  @IBOutlet weak var deliveryTimeWindow  : UILabel! 
  @IBOutlet weak var deliveryAddressLine1  : UILabel! 
  @IBOutlet weak var deliveryAddressLine2  : UILabel! 
  @IBOutlet weak var deliveryAddressLine3  : UILabel! 
  
  
  @IBOutlet weak var totalValue  : UILabel! 
  @IBOutlet weak var totalNumberOfPads  : UILabel! 
  @IBOutlet weak var totalVolume  : UILabel! 
  @IBOutlet weak var totalWeight  : UILabel! 
  @IBOutlet weak var totalNumberDamagedItems  : UILabel! 
  
  
  var jobKey : String!  // caller will provide
  var user : User! // get from delegate
  
  var job : Job!
  var itemsMap : [String : Item] = [:];
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.edgesForExtendedLayout = []
    // self.edgesForExtendedLayout = UIRectEdge.none
    
    assert(jobKey != nil)
   
    let delegate = UIApplication.shared.delegate as! AppDelegate
    user = delegate.currentUser!;
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
  }
  
  func updateTotals(){
    var value = 0
    var numberOfPads = 0
    var volume : Float = 0.0
    var weightLbs : Float = 0.0
    var numberDamagedItems = 0
    for (_, item) in itemsMap{
      value += item.getMonetaryValue()
      numberOfPads += item.getNumberOfPads()
      volume += item.getVolume()
      weightLbs += item.getWeightLbs()
      numberDamagedItems += ((item.getHasClaim()) ? 1 : 0)
      
    }
    
    let currencyFormatter = NumberFormatter()
    currencyFormatter.maximumFractionDigits = 0;
    currencyFormatter.numberStyle = NumberFormatter.Style.currency
    let nsnumber = NSNumber(value: value)
    totalValue.text = currencyFormatter.string( from:nsnumber);
    totalNumberOfPads.text = String(numberOfPads)
    totalVolume.text = String(format:"%.1f", volume) + " ft3";
    totalWeight.text = String(format:"%.0f", weightLbs) + " lbs"
    totalNumberDamagedItems.text = String(numberDamagedItems)
    

  }
  
  func updateFromJob(){
    let pickupDateFormatter = DateFormatter()
    pickupDateFormatter.dateFormat = "M/d/yyyy h:mm a"
    
    
    let pDateTime = job.getPickupDateTime()
    
    let s = pickupDateFormatter.string(from: pDateTime)
    pickupDateTime.text = s;
    
    let pickup = job.originAddress!;
    pickupAddressLine1.text = pickup.street
    if pickup.addressLine2 != nil && (pickup.addressLine2?.lengthOfBytes(using: String.Encoding.utf16))! > 1{
      pickupAddressLine2.text = pickup.addressLine2;
      pickupAddressLine3.text = pickup.city! + ", " + pickup.state! + " " + pickup.zip!;
    } else {
      pickupAddressLine2.text = pickup.city! + ", " + pickup.state! + " " + pickup.zip!;
      pickupAddressLine3.text = "";
    }
    
    fillinDeliveryWindow(job)
  
  }
  
  func fillinDeliveryWindow(_ job : Job){
    let deliveryDateFormatter = DateFormatter()
    deliveryDateFormatter.dateFormat = "M/d/yyyy"


    var windowEarly : String? = nil
    if job.getDeliveryEarliestDate() != nil {
      let adjustedDate = job.getDeliveryEarliestDate()
      windowEarly = deliveryDateFormatter.string(from: adjustedDate!)
    }
    var windowLate : String? = nil;
    if job.getDeliveryLatestDate() != nil {
      let adjustedDate = job.getDeliveryLatestDate()
      windowLate = deliveryDateFormatter.string(from: adjustedDate!)
    }
    var window : String = ""
    if windowEarly != nil{
      window = windowEarly!
    }
    if windowLate != nil {
      if window.lengthOfBytes(using: String.Encoding.utf16) > 0{
        window = window + " - " + windowLate!
      } else {
        window = windowLate!
      }
    }
    if window.lengthOfBytes(using: String.Encoding.utf16) == 0{
      window = "TBD";
    }
    
    deliveryTimeWindow.text = window

    if job.destinationAddress?.street != nil{
      deliveryAddressLine1.text = job.destinationAddress?.street
      let destAddress = job.destinationAddress!
      if destAddress.addressLine2 != nil && (destAddress.addressLine2?.lengthOfBytes(using: String.Encoding.utf16))! > 1{
        deliveryAddressLine2.text = destAddress.addressLine2;
        deliveryAddressLine3.text = destAddress.city! + ", " + destAddress.state! + " " + destAddress.zip!;
      } else {
        deliveryAddressLine2.text = destAddress.city! + ", " + destAddress.state! + " " + destAddress.zip!;
        deliveryAddressLine3.text = "";
      }

    } else {
      deliveryAddressLine1.text = ""
      deliveryAddressLine2.text = ""
      deliveryAddressLine3.text = ""

    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  open func jobUpdate(_ job : Job){
    
    self.job = job;
    updateFromJob()
  }
  
  open func itemsChanged(_ itemsMap : [String : Item]){
    self.itemsMap = itemsMap;
    updateTotals()
  }
}
