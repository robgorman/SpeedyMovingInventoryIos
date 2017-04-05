//
//  PrintViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 11/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase

class PrintViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  @IBOutlet weak var itemTableView: UITableView!
  @IBOutlet weak var noPrintablesMessage: UILabel!
  
  var printables : [Lifecycle] = []
  
  // params
  var jobKey : String!
  var companyKey : String!
  
  var job : Job?
    var jobRef : FIRDatabaseReference!;
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Print a Signoff"
    jobRef = FIRDatabase.database().reference(withPath: "joblists/" + companyKey! + "/jobs/" + jobKey)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.jobRef.observe(FIRDataEventType.value, with: {(snapshot) in
      self.job = Job(snapshot)
      self.updateFromJob()
    })
  }
  
  func updateFromJob(){
    printables = [];
    if job?.signatureLoadedForStorage != nil{
      printables.append(Lifecycle.LoadedForStorage)
    }
    
    if job?.signatureInStorage != nil{
      printables.append(Lifecycle.InStorage)
    }
    if job?.signatureLoadedForDelivery != nil {
      printables.append(Lifecycle.LoadedForDelivery)
    }
    if job?.signatureDelivered != nil{
      printables.append(Lifecycle.Delivered)
    }
    
    if printables.count == 0 {
      noPrintablesMessage.isHidden = false;
      itemTableView.isHidden = true;
    } else {
      noPrintablesMessage.isHidden = true;
      itemTableView.isHidden = false;
    }
    itemTableView.reloadData()
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    jobRef.removeAllObservers()
    
  }
  // DATA Source
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    return printables.count
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
    let cell = tableView.dequeueReusableCell(withIdentifier: "PrintItemTableCell") as! PrintItemTableCell
   //TODO
    var icon : UIImage?
    var message : String?
    let lifecycle = printables[indexPath.row]
    switch lifecycle {
    case .New:
      // this case shouldn't occur
      icon = UIImage(named: "new_active")
      message = "Print \"New\" Signoff";
    case .LoadedForStorage:
      icon = UIImage(named: "loaded_for_storage_active")
      message = "Print \"Loaded For Storage\" Signoff";
    case .InStorage:
      icon = UIImage(named: "in_storage_active")
      message = "Print \"In Storage\" Signoff";
    case .LoadedForDelivery:
      icon = UIImage(named: "loaded_for_delivery_active")
      message = "Print \"Loaded For Delivery\" Signoff";
    case .Delivered:
      icon = UIImage(named: "delivered_active")
      message = "Print \"Delivered\" Signoff";
    }
    cell.label.text = message;
    cell.lifecycleImage.image = icon
    return cell;
    
  }
  
  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
    return 66.0
  }

  
  
  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath){
    // going to go back to caller. lots of data
    // to return;
    let lifecycle = printables[indexPath.row]
    switch lifecycle {
    case .New:
      printSignature((job?.signatureLoadedForStorage)!)
    case .LoadedForStorage:
      printSignature((job?.signatureLoadedForStorage)!)
    case .InStorage:
      printSignature((job?.signatureInStorage)!)
    case .LoadedForDelivery:
      printSignature((job?.signatureLoadedForDelivery)!)
    case .Delivered:
      printSignature((job?.signatureDelivered)!)
      
    }
  }
  
  func printSignature(_ signature : Signature){
    let url = URL(string:signature.imageUrl!);
    if UIPrintInteractionController.canPrint(url!) {
      let printInfo = UIPrintInfo(dictionary: nil)
      printInfo.jobName = (url?.lastPathComponent)!
      printInfo.outputType = .general
      printInfo.orientation = .portrait
    
      let printController = UIPrintInteractionController.shared
      printController.printInfo = printInfo
      printController.showsNumberOfCopies = false
      
      printController.printingItem = url
      
      printController.present(animated: true, completionHandler: nil)
    }
  }

 
   }
