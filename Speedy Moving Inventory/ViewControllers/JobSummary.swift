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
  
  @IBOutlet weak var pickupAddress: UITextView!
  
  @IBOutlet weak var deliveryAddress: UITextView!
 //@IBOutlet weak var pickupAddressLine1  : UILabel!
 //@IBOutlet weak var pickupAddressLine2  : UILabel!
 //@IBOutlet weak var pickupAddressLine3  : UILabel!
  
  @IBOutlet weak var deliveryTimeWindow  : UILabel!
  //@IBOutlet weak var deliveryAddressLine1  : UILabel!
  //@IBOutlet weak var deliveryAddressLine2  : UILabel!
  //@IBOutlet weak var deliveryAddressLine3  : UILabel!
  
  
  @IBOutlet weak var totalValue  : UILabel!
  @IBOutlet weak var totalNumberOfPads  : UILabel! 
  @IBOutlet weak var totalVolume  : UILabel! 
  @IBOutlet weak var totalWeight  : UILabel! 
  @IBOutlet weak var totalNumberDamagedItems  : UILabel!
  
  var tValue : Int = 0
  var tNumberOfPads : Int = 0
  var tVolume : Float = 0.0
  var tWeightLbs : Float = 0.0
  var tNumberOfDamagedItems : Int = 0
  
  
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
    tValue = 0
    tNumberOfPads = 0
    tVolume  = 0.0
    tWeightLbs  = 0.0
    tNumberOfDamagedItems = 0
    for (_, item) in itemsMap{
      tValue +=  item.getMonetaryValue()
      tNumberOfPads +=  item.getNumberOfPads()
      tVolume +=  item.getVolume()
      tWeightLbs += item.getWeightLbs()
      tNumberOfDamagedItems += ((item.getHasClaim()) ? 1 : 0)
      
    }
    
    let currencyFormatter = NumberFormatter()
    currencyFormatter.maximumFractionDigits = 0;
    currencyFormatter.numberStyle = NumberFormatter.Style.currency
    let nsnumber = NSNumber(value: tValue)
    totalValue.text = currencyFormatter.string( from:nsnumber);
    totalNumberOfPads.text = String(tNumberOfPads)
    let s = String(format:"%.1f", tVolume) + " ft3";
    totalVolume.attributedText = TextUtils.formFt3Superscript(text: s);
    totalWeight.text = String(format:"%.0f", tWeightLbs) + " lbs"
    totalNumberDamagedItems.text = String(tNumberOfDamagedItems)
    

  }
  
  func updateFromJob(){
    let pickupDateFormatter = DateFormatter()
    pickupDateFormatter.dateFormat = "M/d/yy h:mm a"
    
    
    let pDateTime = job.getPickupDateTime()
    
    let s = pickupDateFormatter.string(from: pDateTime)
    pickupDateTime.text = s;
    
    let pickup = job.originAddress!;
    pickupAddress.text = pickup.street
    if pickup.addressLine2 != nil && (pickup.addressLine2?.lengthOfBytes(using: String.Encoding.utf16))! > 1{
      pickupAddress.text = pickupAddress.text + "\n" + pickup.addressLine2!
      pickupAddress.text = pickupAddress.text + "\n" + pickup.city! + ", " + pickup.state! + " " + pickup.zip!;
    } else {
      pickupAddress.text = pickupAddress.text +
       "\n" + pickup.city! + ", " + pickup.state! + " " + pickup.zip!;
     
    }
    
    fillinDeliveryWindow(job)
  
  }
  
  func fillinDeliveryWindow(_ job : Job){
    let deliveryDateFormatter = DateFormatter()
    deliveryDateFormatter.dateFormat = "M/d/yy"


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
      deliveryAddress.text = job.destinationAddress?.street
      let destAddress = job.destinationAddress!
      if destAddress.addressLine2 != nil && (destAddress.addressLine2?.lengthOfBytes(using: String.Encoding.utf16))! > 1{
        deliveryAddress.text = deliveryAddress.text + "\n" +  destAddress.addressLine2!
        deliveryAddress.text = deliveryAddress.text  + "\n" + destAddress.city! + ", " + destAddress.state! + " " + destAddress.zip!
        
      } else {
        deliveryAddress.text = deliveryAddress.text
          + "\n" + destAddress.city! + ", " + destAddress.state! + " " + destAddress.zip!;
        
      }

    } else {
      deliveryAddress.text = ""
      
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
