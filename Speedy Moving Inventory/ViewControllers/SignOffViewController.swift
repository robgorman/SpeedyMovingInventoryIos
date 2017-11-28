//
//  SignOffActivity.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/5/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import SwiftSignatureView
import Firebase

class SignOffViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SwiftSignatureViewDelegate{
  
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var companyNameLabel: UILabel!
  @IBOutlet weak var companyPhone: UILabel!
  @IBOutlet weak var companyAddressLabel: UILabel!
  @IBOutlet weak var foremanLabel: UILabel!
  @IBOutlet weak var logoImage: UIImageView!
  @IBOutlet weak var shipperNameLabel: UILabel!
  @IBOutlet weak var shipperPhoneLabel: UILabel!
  @IBOutlet weak var shipperAddressLabel: UILabel!
  @IBOutlet weak var shipperEmailLabel: UILabel!
  @IBOutlet weak var usDotLabel: UILabel!
  @IBOutlet weak var iccMcLabel: UILabel!
  @IBOutlet weak var calTLabel: UILabel!
  
  @IBOutlet weak var newImage: UIImageView!
  @IBOutlet weak var loadedForStorageImage: UIImageView!
  @IBOutlet weak var inStorageImage: UIImageView!
  @IBOutlet weak var loadedForDeliveryImage: UIImageView!
  @IBOutlet weak var deliveredImage: UIImageView!
  @IBOutlet weak var summaryLabel: UILabel!
  
  @IBOutlet weak var jobInfoLabel: UILabel!
  @IBOutlet weak var signatureNameTextField: UITextField!
  
  @IBOutlet weak var signatureView: SwiftSignatureView!
  @IBOutlet weak var signHereHintLabel: UILabel!
  @IBOutlet weak var acceptButton: UIButton!
  
  @IBOutlet weak var savingView: UIView!
  
  // params
  var companyKey : String!
  var jobKey : String!
  var entryLifecycle : Lifecycle!
  var storageInTransit : Bool!
  var totalItems : Int!
  var totalValue : Float!
  var totalPads : Int!
  var totalVolumeCubicFeet : Float!
  var totalWeight : Float!
  var totalDamagedItems : Int!
  ////////////
  var onDoneBlock : () -> Void = {return}
  
  var company : Company?
  var job : Job?
  var successfulSignoff = false;
  
  func updateLifecycle(job : Job){
    if job.getStorageInTransit(){
      loadedForStorageImage.isHidden = false;
      inStorageImage.isHidden = false;
    } else {
      loadedForStorageImage.isHidden = true;
      inStorageImage.isHidden = true;
    }
    
    switch job.getLifecycle(){
    case .New:
      newImage.image = UIImage(named:"new_active")
    case .LoadedForStorage:
      loadedForStorageImage.image = UIImage(named: "loaded_for_storage_active")
    case .InStorage:
      inStorageImage.image = UIImage(named: "in_storage_active")
    case .LoadedForDelivery:
      loadedForDeliveryImage.image = UIImage(named: "loaded_for_delivery_active")
    case .Delivered:
      deliveredImage.image = UIImage(named: "delivered_active")
    }
  }
  
  func updateFromJob(){
    if job == nil{
      // this is error
      return;
    }
    
    shipperNameLabel.text = (job?.customerFirstName)! + " " + (job?.customerLastName)!
    shipperPhoneLabel.text = PhoneNumberFormatter.format((job?.customerPhone)!);
    shipperAddressLabel.text = TextUtils.formSingleLineAddress(address: (job?.destinationAddress)!)
    shipperEmailLabel.text = job?.customerEmail
    
    jobInfoLabel.text = "Job Number: " + (job?.jobNumber)! + " " + determineSignOffTitle();
    updateLifecycle(job: job!);
    
    //jobInfoLable.text =
    
  }
  
  func loadJob(){
    var jobRef : FIRDatabaseReference!;
    jobRef = FIRDatabase.database().reference(withPath: "joblists/" + companyKey + "/jobs/" + jobKey)
    jobRef.observe(FIRDataEventType.value, with: {(snapshot) in
      self.job = Job(snapshot)
      self.updateFromJob();
      self.summaryLabel.text = self.constructSummary();
    })
  }
  
  // we don't have makeGone and Show
  
  func updateFromCompany(){
    if company == nil {
      return
    }
    
    companyNameLabel.text = company?.name
    companyAddressLabel.text = TextUtils.formSingleLineAddress(address: (company?.address)!)
    companyPhone.text = PhoneNumberFormatter.format((company?.phoneNumber)!)
    
    usDotLabel.text = company?.usDot
    iccMcLabel.text = company?.iccMc
    calTLabel.text = company?.calT
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var logoUrl = appDelegate.currentCompany?.logoUrl
    let url = URL(string: logoUrl!)
    if logoUrl != nil && (logoUrl?.characters.count)! > 0 {
      logoImage.af_setImage(withURL : url!, placeholderImage : UIImage(named:"transparent"))
    }
  }
  
  func moveDestination() -> String{
    var result = "";
    let lifecycle : Lifecycle = (job?.getLifecycle())!
    switch lifecycle {
    case .New:
      if (job?.getStorageInTransit())!{
        result = "Storage"
      } else {
        result = TextUtils.formSingleLineAddress(address: (job?.destinationAddress)!)
      }
    case .LoadedForStorage:
      result = "Storage"
    case .InStorage:
      result = TextUtils.formSingleLineAddress(address: (job?.destinationAddress)!)
    case .LoadedForDelivery:
      result = TextUtils.formSingleLineAddress(address: (job?.destinationAddress)!)
    case .Delivered:
      result = TextUtils.formSingleLineAddress(address: (job?.destinationAddress)!)
    }
    return result
  }
  
  func constructSummary() -> String {
    let currencyFormatter = NumberFormatter();
    currencyFormatter.maximumFractionDigits = 2
    currencyFormatter.numberStyle = NumberFormatter.Style.currency
    
    let nsnumber = NSNumber(value: totalValue!);
    let totalValueString = currencyFormatter.string(from: nsnumber);
    let ti = totalItems
    var summary = "• " + String(ti!);
    
    // don't add value to summary if company options say so. 
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    if (appDelegate.currentCompany?.getExposeValueToCustomers())!{
      // don't add value
      summary = summary + " Items valued at " + totalValueString! + "\n";
    } else {
      summary = summary + " Items \n"
    }
    
    summary = summary + "• " + "Move destination is " ;
    summary = summary + moveDestination() + "\n";
    return summary
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    signatureView.delegate = self
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "EEE, MMM d yyyy, h:mm a z";
   
    let now = Date()
    dateLabel.text = dateFormatter.string(from : now);
    foremanLabel.text = (appDelegate.currentUser?.firstName)! + " " + (appDelegate.currentUser?.lastName)!
    
    loadJob();
    company = appDelegate.currentCompany;
    updateFromCompany()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    successfulSignoff = false; 
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }
  
  func screenShot() -> UIImage{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, UIScreen.main.scale)
    
    self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
    
    // old style: layer.renderInContext(UIGraphicsGetCurrentContext())
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  @IBAction func resetPressed(_ sender: Any) {
    signatureView.clear();
    signHereHintLabel.isHidden = false;
    acceptButton.isEnabled = false;
  }
  
  @IBAction func acceptPressed(_ sender: Any) {
    if signatureNameTextField.text?.characters.count == 0{
      UiUtility.showAlert("Missing Name", message: "You must type your name in the space provided", presenter: self)
      return
    }
    
    let screen = screenShot();
    saveChanges(signatureImage: screen, name: signatureNameTextField.text!)
    
  }
  func saveChanges(signatureImage : UIImage, name : String){
    // TODO
    savingView.isHidden = false;
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let path = "signatures/" + companyKey + "/" + jobKey + "/" + entryLifecycle.rawValue

    //let storage = FIRStorage.storage();
    //let rref = storage.reference(forURL: appDelegate.storageUrl!)
    //let sig = rref.child(path);
    
    let customerSignature = FIRStorage.storage()
           .reference(forURL: appDelegate.storageUrl!).child(path )
    
    let data = UIImageJPEGRepresentation(signatureImage, 0.55)
    let _ = customerSignature.put(data!, metadata: nil, completion: {
      metadata, error in
      if error != nil {
        
        UiUtility.showAlert("Upload Failed", message: "Signature upload failed. Try again. Error: "
          + (error?.localizedDescription)!, presenter: self)
      } else {
        let nextState = self.getNextLifecycle();
        // update teh lifecycle
      
        FIRDatabase.database().reference(withPath: "joblists/" + self.companyKey + "/jobs/" + self.jobKey).child("lifecycle").setValue(nextState.rawValue);
        let url = metadata?.downloadURL()
              let signature = Signature(name: name , imageUrl: (url?.absoluteString)!, signOffDateTime: Date())
        FIRDatabase.database().reference(withPath: "joblists/" + self.companyKey + "/jobs/" + self.jobKey).child("signature" + nextState.rawValue)
          .setValue(signature.asFirebaseObject());
        
        // TODO mark all items as unscannd and send signoff email
        self.successfulSignoff = true;
        self.onDoneBlock()
        self.dismiss(animated: true, completion: nil)
        self.savingView.isHidden = false;
      }
    })
  }
  
  
  @IBAction func cancelPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func determineSignOffTitle() -> String{
    let lifecycle : Lifecycle = entryLifecycle
    switch lifecycle {
    case .New:
      return "Pickup"
    case .LoadedForStorage:
      return "Unload Warehouse"
    case .InStorage:
      return "Loaded on Truck"
    case .LoadedForDelivery:
      return "Delivery"
    case .Delivered:
      // this shouln't happne
      return ""
      
    }
  }
  
  private func getNextLifecycle() -> Lifecycle{
    if entryLifecycle == Lifecycle.New && storageInTransit{
      return Lifecycle.LoadedForStorage
    } else if entryLifecycle == Lifecycle.New && !storageInTransit {
      return Lifecycle.LoadedForDelivery;
    } else if entryLifecycle == Lifecycle.LoadedForStorage  {
      return Lifecycle.InStorage;
    }else if entryLifecycle == Lifecycle.InStorage {
      return Lifecycle.LoadedForDelivery;
    } else if entryLifecycle == Lifecycle.LoadedForDelivery{
      return Lifecycle.Delivered;
    } else {
      // some error/ try to fail fast
      return Lifecycle.New;
    }
  }
  
  //MARK: Delegate
  
  public func swiftSignatureViewDidTapInside(_ view: SwiftSignatureView) {
    print("Did tap inside")
    // hide the signoff
    signHereHintLabel.isHidden = true;
    acceptButton.isEnabled = true;
    
  }
  
  public func swiftSignatureViewDidPanInside(_ view: SwiftSignatureView) {
    print("Did pan inside")
    signHereHintLabel.isHidden = true;
    acceptButton.isEnabled = true;
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }

}
