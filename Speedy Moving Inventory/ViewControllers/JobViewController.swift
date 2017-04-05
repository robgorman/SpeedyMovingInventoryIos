//
//  JobViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import AVFoundation
import AudioToolbox
import CoreLocation



class JobViewController : UIViewController, QRCodeReaderViewControllerDelegate, CLLocationManagerDelegate {
  
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var summaryView: UIView!
  @IBOutlet weak var detailsView: UIView!
  //@IBOutlet weak var labelEmail: UILabel!
  @IBOutlet weak var phoneNumberTextView: UITextView!
 
  @IBOutlet weak var emailTextView: UITextView!
  //@IBOutlet weak var labelPhone: UILabel!
  @IBOutlet weak var labelScanned: UILabel!
  
  @IBOutlet weak var newStatusImage: UIImageView!
  @IBOutlet weak var deliveredStatusImage: UIImageView!
  @IBOutlet weak var loadedForDeliveryStatusImage: UIImageView!
  @IBOutlet weak var inStorageStatusImage: UIImageView!
  @IBOutlet weak var loadedForStorageStatusImage: UIImageView!
  
  
  @IBOutlet weak var newStatusLabel: UILabel!
  @IBOutlet weak var loadedForStorageStatusLabel: UILabel!
  @IBOutlet weak var inStorageStatusLabel: UILabel!
  @IBOutlet weak var loadedForDeliveryStatusLabel: UILabel!
  @IBOutlet weak var deliveredStatusLabel: UILabel!
  
  @IBOutlet weak var loadingView: UIView!
  @IBOutlet weak var loadedView: UIView!
  var jobKey : String!  // caller will provide
  var companyKey : String! // caller must provide
  var jobRef : FIRDatabaseReference!;
  var recipientListQuery : FIRDatabaseQuery!
  
  var recipientList = ""   // maintains recipientlist
  
  var itemsRef : FIRDatabaseReference!
  var itemsMap : [String : Item] = [:];
  
  var job : Job!
  var jobSummary : JobSummary!
  var jobDetails : JobDetails!
  
  var dateFormatter : DateFormatter!;
  
  var user : User!;
  var loading = false;
  
  var processingCode = false;
  var allowItemAddOutsideNew = true;
  // Good practice: create the reader lazily to avoid cpu overload during the
  // initialization and each time we need to scan a QRCode
  lazy var readerVC = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder {
    var o = $0;
    o.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
  })

 
  
  var settings : UIBarButtonItem?
  
  let locationManager = CLLocationManager();
  var currentLocation : CLLocationCoordinate2D?
  var canScan = false;
  
  var firstTime = true;

  override func viewDidLoad() {
    super.viewDidLoad()
    settings = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(JobViewController.settingsPressed))
    
    self.navigationItem.rightBarButtonItem = settings
    
    firstTime = true;
   
  
    self.edgesForExtendedLayout = []
   // self.edgesForExtendedLayout = UIRectEdge.none
    assert(jobKey != nil)
    let delegate = UIApplication.shared.delegate as! AppDelegate
    user = delegate.currentUser;
    assert(user != nil)
    jobRef = FIRDatabase.database().reference(withPath: "joblists/" + companyKey + "/jobs/" + jobKey)
    recipientListQuery = FIRDatabase.database()
      .reference(withPath: "/companyUserAssignments/")
      .queryOrdered(byChild: "companyKey")
      .queryStarting(atValue: companyKey)
      .queryEnding(atValue: companyKey)
    
    itemsRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items")

   
    labelScanned.text = ""
    dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "M/d/yy";
    
    emailTextView.isEditable = false;
    emailTextView.textContainer.maximumNumberOfLines = 1;
    emailTextView.textContainer.lineBreakMode = .byTruncatingTail
    
    phoneNumberTextView.isEditable = false;
    phoneNumberTextView.textContainer.maximumNumberOfLines = 1;
    phoneNumberTextView.textContainer.lineBreakMode = .byTruncatingTail
    //emailView.isEditing = false;
   
    locationManager.requestWhenInUseAuthorization();
    
  }
  
  //DispatchQueue.global(qos: .background).async {
  //print("This is run on the background queue")
  
  ///DispatchQueue.main.async {
  //print("This is run on the main queue, after the previous code in outer block")
  //}
  //}
  
  func updateVisibility(){
    loadingView.isHidden = !loading;
    loadedView.isHidden = loading;
  }
  
  var handle : UInt = 0;
  
  func remove(){
    itemsRef.removeObserver(withHandle: handle);
  }
  
  
  
  override func viewWillAppear(_ animated: Bool) {
    
    let authorizationStatus = CLLocationManager.authorizationStatus()
    if authorizationStatus == .denied || authorizationStatus == .denied{
      UiUtility.showAlert("Location Services Required", message: "You must enable location services in order to scan items.", presenter: self)
      canScan = false;

    } else if (CLLocationManager.locationServicesEnabled()){
      locationManager.delegate = self;
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
      locationManager.startUpdatingLocation()
      canScan = true;
      currentLocation = locationManager.location?.coordinate;
    } else {
      UiUtility.showAlert("Location Services Required", message: "You must enable location services in order to scan items.", presenter: self)
      canScan = false;
    }

    //Hud.on(self)
    loading = true;
    updateVisibility();
    
    self.jobRef.observe(FIRDataEventType.value, with: {(snapshot) in
      self.job = Job(snapshot)
      self.updateFromJob();
      //Hud.off(self)
      self.loading = false;
      self.updateVisibility();
    })
    
    handle = self.itemsRef.observe(FIRDataEventType.value, with:{(snapshot) in
      // this is just a test for any items we aren't really reading anything
      if !snapshot.exists() {
        self.labelScanned.text = "No Moving Items"
      }
      self.remove()
    })
    
    self.itemsRef.observe(FIRDataEventType.childAdded, with:{(snapshot) in
      let item = Item(snapshot)
      self.itemsMap[snapshot.key] = item;
      self.itemsChanged()
    })
    
    self.itemsRef.observe(FIRDataEventType.childChanged, with:{(snapshot) in
      let item = Item(snapshot)
      self.itemsMap[snapshot.key] = item;
      self.itemsChanged()
    })
    self.itemsRef.observe(FIRDataEventType.childRemoved, with:{(snapshot) in
      self.itemsMap.removeValue(forKey: snapshot.key)
      self.itemsChanged()
    })

    
    if (recipientListQuery != nil){
      recipientListQuery.observe(FIRDataEventType.value, with:{(snapshot) in
        if !snapshot.exists(){
          // some sort of error
          UiUtility.showAlert("Unexpected Error", message: "Error reading email recipients.", presenter: self)
        } else {
          for next in snapshot.children{
            //nextSnapshot.
             let nextSnapshot = next as! FIRDataSnapshot;
            self.handleNext(nextSnapshot: nextSnapshot)
            
          }
        }
        
      })
    }
    
  }
  
  func handleNext(nextSnapshot : FIRDataSnapshot){
    
    let uca = UserCompanyAssignment(nextSnapshot);
    let ref = FIRDatabase.database().reference(withPath: "/users/" + uca.uid!)
    ref.observeSingleEvent(of: .value, with: {(snapshot) in
      if snapshot.exists(){
        let user = User(snapshot);
        if uca.getRole() == Role.CompanyAdmin {
          if self.recipientList.characters.count == 0{
            self.recipientList = user.emailAddress!
          } else {
            self.recipientList = self.recipientList + "," + user.emailAddress!
          }
        }
        
      }
    });

  }
  
  func itemsChanged(){
    jobSummary.itemsChanged(itemsMap)
    
    var scanned = 0;
    for (_, item) in itemsMap{
      if item.getIsScanned(){
        scanned += 1
      }
    }
    if job != nil && (job.getLifecycle() == Lifecycle.New){
      labelScanned.text = String(itemsMap.count) + " Items"
    } else {
      labelScanned.text = "Scanned " + String(scanned);
      labelScanned.text = labelScanned.text! + " of " + String(itemsMap.count) + " Items"
    }
    
    if (itemsMap.count > 1 && firstTime){
      firstTime = false;
      segmentedControl.selectedSegmentIndex = 1;
      onChangedSegmentControl(segmentedControl);
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {

    jobRef.removeAllObservers()
    itemsRef.removeAllObservers()
    if (recipientListQuery != nil){
      recipientListQuery.removeAllObservers()
    }
    
   
    locationManager.stopUpdatingLocation();
    

  }
  
  func updateFromJob(){
    jobSummary.jobUpdate(job)
    jobDetails.jobUpdate(job)
    //labelEmail.text = job.customerEmail
    
    
    newStatusLabel.isHidden = true;
    loadedForStorageStatusLabel.isHidden = true;
    inStorageStatusLabel.isHidden = true;
    loadedForDeliveryStatusLabel.isHidden = true;
    deliveredStatusLabel.isHidden = true;

    if (job.getStorageInTransit()){
      // hide loaded for storage and in storage
      loadedForStorageStatusImage.isHidden = false;
      inStorageStatusImage.isHidden = false;
    } else {
      loadedForStorageStatusImage.isHidden = true;
      inStorageStatusImage.isHidden = true;

    }

    newStatusImage.image = UIImage(named: "new_")
    loadedForStorageStatusImage.image = UIImage(named: "loaded_for_storage")
    inStorageStatusImage.image = UIImage(named: "in_storage")
    loadedForDeliveryStatusImage.image = UIImage(named: "loaded_for_delivery")
    deliveredStatusImage.image = UIImage(named: "delivered")
    
    switch (job.getLifecycle()){
    case .New:
      newStatusImage.image = UIImage(named: "new_active")
      newStatusLabel.isHidden = false;
    case .LoadedForStorage:
      loadedForStorageStatusImage.image = UIImage(named: "loaded_for_storage_active")
      loadedForStorageStatusLabel.isHidden = false;
    case .InStorage:
      inStorageStatusImage.image = UIImage(named: "in_storage_active")
      inStorageStatusLabel.isHidden = false;
    case .LoadedForDelivery:
      loadedForDeliveryStatusImage.image = UIImage(named: "loaded_for_delivery_active")
      loadedForDeliveryStatusLabel.isHidden = false;
    case .Delivered:
      deliveredStatusImage.image = UIImage(named: "delivered_active")
      deliveredStatusLabel.isHidden = false;

    }
    
   // labelPhone.text = PhoneNumberFormatter.format(job.customerPhone!)
    
    navigationItem.title = "(" + job.jobNumber! + ")"
    navigationItem.title = navigationItem.title!  + " " + job.customerFirstName! + " " + job.customerLastName!;
    
    let attributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
    let phNumber = PhoneNumberFormatter.format(job.customerPhone!)
    let attributedString = NSMutableAttributedString(string: phNumber, attributes: attributes)
    
    phoneNumberTextView.attributedText = attributedString;
    phoneNumberTextView.font = UIFont(name:"System Regular", size:28);
//
    let emailString = NSAttributedString(string: job.customerEmail!, attributes: attributes)
    emailTextView.attributedText = emailString;
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  @IBAction func onChangedSegmentControl(_ sender: AnyObject) {
    let segmentControl = sender as! UISegmentedControl
    
    switch segmentControl.selectedSegmentIndex{
    case 0:
      summaryView.isHidden = false;
      detailsView.isHidden = true;
    case 1:
      summaryView.isHidden = true;
      detailsView.isHidden = false;
    default:
      summaryView.isHidden = false;
      detailsView.isHidden = true;

    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let name = segue.identifier;
    if name == "summarySegue"{
      jobSummary = segue.destination as! JobSummary;
      jobSummary.jobKey = jobKey
    } else if name == "detailsSegue"{
      jobDetails = segue.destination as! JobDetails
      jobDetails.jobKey = jobKey
      jobDetails.companyKey = companyKey
    }
  }
  
  func launchScanActivity(){
    
    if job.getLifecycle() == Lifecycle.Delivered{
      UiUtility.showAlert("Job is Complete", message: "The Job is complete. No further scanning is possible", presenter: self)
      return;
    }
    
    
    // Retrieve the QRCode content
    // By using the delegate pattern
    readerVC.delegate = self
    
    
    //readerVC.showTorchButton = true;
    
    // Or by using the closure pattern
    readerVC.completionBlock = { (result: QRCodeReaderResult?) in
      if result != nil{
        print(result!)
      }
    }
    self.navigationController?.pushViewController(readerVC, animated: true)
  }

  
  @IBAction func scanPressed(_ sender: AnyObject) {
    if canScan{
      self.readerVC.messageLabel.text = "Point camera at a QRC Code"
      self.launchScanActivity()
    } else {
      UiUtility.showAlert("Cannot Access Scanner", message: "You must enable location services in order to use the scanner.", presenter: self)
    }
  }
  
  // MARK: - QRCodeReaderViewController Delegate Methods
  
  //func reader(_ reader: QRCodeReader.QRCodeReaderViewController, didScanResult result: QRCodeReader.QRCodeReaderResult) {
  func reader(_ codeReaderViewController: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
    if processingCode{
      return;
    }
    processingCode = true
    barcodeScanned(code: result.value, codeReaderViewController: codeReaderViewController);
        //dismiss(animated: true, completion: nil)
  }
 
  var itemKeyRef : FIRDatabaseReference!
  
  func barcodeScanned(code : String, codeReaderViewController : QRCodeReaderViewController){
    if !Utility.isQrcCodeValid(code: code){
      invalidCodeUserFeedback(codeReaderViewContoller: codeReaderViewController);
      processingCode = false;
      return;
    }
    //codeReaderViewContoller.messageLabel.text = "Point camera at a QRC Code"
    itemKeyRef = FIRDatabase.database().reference(withPath: "qrcList/" + code)
    
    itemKeyRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
      if !snapshot.exists(){
        // item is new
        if self.job.getLifecycle() != Lifecycle.New && !self.allowItemAddOutsideNew{
          // its an error
         
          self.negativeFeedback(codeReaderViewController: codeReaderViewController, message: "This does not belong to this job.");
          self.processingCode = false;
        } else {
          self.positiveFeedback(codeReaderViewController: codeReaderViewController)
          let isOutOfPhase = self.job.getLifecycle() != Lifecycle.New;
          self.createNewItem(job: self.job, code: code, codeReaderViewContoller: codeReaderViewController, itemIsOutOfPhase: isOutOfPhase)
          self.processingCode = false;
          self.allowItemAddOutsideNew = false;
        }
        
        
      } else {
        // item exists see if its in ths job
        let jobKey = snapshot.value as! String
        if jobKey != self.jobKey{
          self.negativeFeedback( codeReaderViewController: codeReaderViewController, message: "This item belongs to another job")
          self.processingCode = false;
        } else {
          self.lookupSuccessFeedback(codeReaderViewController: codeReaderViewController)
          
          let itemRef = FIRDatabase.database().reference(withPath: "/itemlists/" + self.jobKey + "/items/" + code)
          itemRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
            let item = Item(snapshot)
            
            if self.job.getLifecycle() == .New {
              self.editItem(job: self.job, code: code, item: item, codeReaderViewController:  codeReaderViewController)
            } else { // for any other job lifecycle just mark as scanned
              let isScanned = item.getIsScanned();
              if isScanned {
                self.alreadyScannedFeedback(codeReaderViewController: codeReaderViewController);
                
              } else {
                // set item as scanned
               //let scanRecord = ScanRecord(Date(),
                var latitude = 0.0;
                var longitude = 0.0;
                if self.currentLocation != nil{
                  latitude = (self.currentLocation?.latitude)!
                  longitude = (self.currentLocation?.longitude)!;
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let scanRecord = ScanRecord(scanDateTime: Date(), latitude: latitude, longitude: longitude, uidOfScanner: (appDelegate.currentUser?.uid)!,
                                            isScanOverride: false, lifecycle: self.job.getLifecycle())
                let ref = FIRDatabase.database().reference(withPath: "/scanHistory/" + code).childByAutoId()
                ref.setValue(scanRecord.asFirebaseObject())
                
                FIRDatabase.database().reference(withPath: "/itemlists/" + self.jobKey + "/items/" + code ).child("isScanned").setValue(true)
              }
            }
            self.processingCode = false;
          })
        }
      }
     
      
    })

  }
  
  
  func alreadyScannedFeedback(codeReaderViewController : QRCodeReaderViewController){
    codeReaderViewController.messageLabel.text = "This item has already been scanned."
   
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }
  
  func lookupSuccessFeedback(codeReaderViewController : QRCodeReaderViewController){
    Utility.playSound(file: "alreadyscanned", type: "mp3");
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

  }
  
  func positiveFeedback(codeReaderViewController : QRCodeReaderViewController){
    Utility.playSound(file: "success", type: "mp3");
  }
  func negativeFeedback(codeReaderViewController : QRCodeReaderViewController, message : String){
    codeReaderViewController.messageLabel.text = message
    Utility.playSound(file: "negative_beep", type: "wav");
     AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }
  
  func createNewItem(job : Job, code : String, codeReaderViewContoller: QRCodeReaderViewController, itemIsOutOfPhase : Bool){
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
    vc.jobKey = jobKey
    vc.qrcCode = code;
    vc.companyKey = self.companyKey
    vc.itemWasCreatedOutOfPhase = itemIsOutOfPhase;
    let backItem = UIBarButtonItem();
    backItem.title = "Scan Next";
    codeReaderViewContoller.navigationItem.backBarButtonItem = backItem;
    codeReaderViewContoller.navigationController?.pushViewController(vc, animated: true);
  }
  
  func editItem(job : Job, code : String, item : Item, codeReaderViewController: QRCodeReaderViewController){
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
    vc.jobKey = jobKey
    vc.qrcCode = code;
    vc.companyKey = self.companyKey
    vc.itemWasCreatedOutOfPhase = false;
    let backItem = UIBarButtonItem();
    backItem.title = "Scan Next";
    codeReaderViewController.navigationItem.backBarButtonItem = backItem;

    codeReaderViewController.navigationController?.pushViewController(vc, animated: true);
  }

  
  func invalidCodeUserFeedback(codeReaderViewContoller : QRCodeReaderViewController){
    var soundId : SystemSoundID = 0;
    let filePath = Bundle.main.path(forResource: "negative_beep_2", ofType: "wav")
    let soundURL = NSURL(fileURLWithPath: filePath!)
 
    AudioServicesCreateSystemSoundID(soundURL, &soundId)
    AudioServicesPlaySystemSound(soundId)
    
    codeReaderViewContoller.messageLabel.text = "Invalid QRC Code -- Not a Speedy Moving Inventory Code"
  }
  
  func readerDidCancel(_ reader: QRCodeReaderViewController) {
    //dismiss(animated: true, completion: nil)
    
    reader.dismiss(animated: true, completion: nil)
  }
  
  func launchSignOffActivity(){
    let appDelegate = UIApplication.shared.delegate as! AppDelegate;
    let role = appDelegate.userCompanyAssignment?.getRole();
    if role == Role.AgentCrewMember || role == Role.CrewMember || role == Role.Customer {
      UiUtility.showAlert("Not Authorized", message: "Your role must be Foreman or greater in order to signoff.", presenter: self)
    }else {
      let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SignOffViewController")) as! SignOffViewController;
      vc.companyKey = companyKey
      vc.jobKey = jobKey
      vc.entryLifecycle = job.getLifecycle()
      vc.storageInTransit = job.getStorageInTransit()
   
        let jvc = jobSummary
        vc.totalItems = itemsMap.count
        vc.totalValue = jvc?.tValue
        vc.totalPads = jvc?.tNumberOfPads
        vc.totalVolumeCubicFeet = jvc?.tVolume
        vc.totalWeight = jvc?.tWeightLbs
        vc.totalDamagedItems = jvc?.tNumberOfDamagedItems
      
      
      //self.navigationController?.pushViewContr
      vc.modalPresentationStyle = .fullScreen
      vc.modalTransitionStyle = .coverVertical
      vc.onDoneBlock = {
        if vc.successfulSignoff{
          self.markAllItemsUnScanned();
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // in tenth of sec.
             self.sendSignoffEmail()
          }
          
        }
         
      }
      present(vc, animated: true, completion: nil)
    }
  }
  
  func markAllItemsUnScanned(){
    let ref = FIRDatabase.database().reference(withPath: "/itemlists/" + jobKey + "/items/");
    for (key, _) in itemsMap{
      ref.child(key + "/isScanned").setValue(false);
     
    }

  }
  
  func sendLifecycleSignOffEmail(){
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let recipients =  recipientList
    let companyName = delegate.currentCompany?.name;
    let companyPhone = delegate.currentCompany?.phoneNumber;
    
    let linkUrl = delegate.webAppUrl
 
    let customerName = job.customerFirstName! + " " + job.customerLastName!
    let lifecycle = job.lifecycle
    let jobNumber = job.jobNumber
    
    let server = delegate.mailServer;
    server?.sendNewSignoffEmailMessage(recipients: recipients,
                                       companyName: companyName!,
                                       linkUrl: linkUrl!,
                                       customerName: customerName,
                                       lifecycle: lifecycle!,
                                       jobNumber: jobNumber!,
                                       companyPhone: companyPhone!,
                                       success: { (message) in
                                        UiUtility.showAlert("Emails Sent", message: "Signoff emails successfully sent.", presenter: self)
    },
                                       failure: {(message) in
                                        UiUtility.showAlert("Email Failure", message: "Signoff successful but emails not sent." + message, presenter: self)
    })
    

  }
  
  func sendNewJobSignOffEmail(){
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let recipients = job.customerEmail! + "," + recipientList
    let companyName = delegate.currentCompany?.name;
    let companyPhone = delegate.currentCompany?.phoneNumber;
    
    let linkUrl = delegate.webAppUrl! + "/user-sign-up";
    let customerName = job.customerFirstName! + " " + job.customerLastName!
    let lifecycle = job.lifecycle
    let jobNumber = job.jobNumber
    
    let server = delegate.mailServer;
    server?.sendNewSignoffEmailMessage(recipients: recipients,
                                       companyName: companyName!,
                                       linkUrl: linkUrl,
                                       customerName: customerName,
                                       lifecycle: lifecycle!,
                                       jobNumber: jobNumber!,
                                       companyPhone: companyPhone!,
    success: { (message) in
       UiUtility.showAlert("Emails Sent", message: "Signoff emails successfully sent.", presenter: self)
    },
    failure: {(message) in
      UiUtility.showAlert("Email Failure", message: "Signoff successful but emails not sent." + message, presenter: self)
    })
  
  }
  
  func sendSignoffEmail(){
    let job = self.job;
    if job?.getLifecycle() == Lifecycle.New{
      sendNewJobSignOffEmail()
    } else {
      sendLifecycleSignOffEmail();
    }
  }
  
  func allItemsMarkedAsScanned() -> Bool{
    for (_, item) in itemsMap{
      if !item.getIsScanned(){
        return false;
      }
    }
    return true;
  }
  
  @IBAction func signOffPressed(_ sender: AnyObject) {
    if itemsMap.count <= 0{
      UiUtility.showAlert("No Items", message: "Signoff is not permitted unless there is at least one item.", presenter: self);
      return;
    }

    
    let lifecycle = job.getLifecycle()
    if lifecycle == Lifecycle.Delivered{
      UiUtility.showAlert("Job is Complete", message: "The Job is complete. No further signnoff is possible", presenter: self)
      return;
    }
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
   
    let role = delegate.userCompanyAssignment?.getRole()
    
    if role == Role.AgentCrewMember || role == Role.CrewMember
      || role == Role.Customer{
      UiUtility.showAlert("User Role Error", message: "You must be assigned as Foreman or above to signoff.", presenter: self)
      return;
    }
     // we can sign off if the job lifecycle is new no matter what
    if lifecycle == Lifecycle.New{
      launchSignOffActivity()
    } else {
      if allItemsMarkedAsScanned(){
          launchSignOffActivity()
        } else {
          UiUtility.showAlert("Unscanned Items", message: "Not all items are scanned. Scan all items before signoff.", presenter: self)
      }
    }
    
  }
  
  @IBAction func onTouched(_ sender: Any) {
    print("stuff");
  }
  
  
  func settingsPressed(){
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let logoutAction = UIAlertAction(title: "Logout", style: .default, handler: {(action) in
      self.logout();
    })
    
    let aboutAction = UIAlertAction(title: "About", style: .default, handler: {(action) in
      self.about()
    })
    
    let printAction = UIAlertAction(title: "Print", style: .default, handler: {(action) in
      self.launchPrintSignature()
    })
    
    let newItemOverride = UIAlertAction(title: "New Item Override", style: .default, handler: {(action) in
      if self.job.getLifecycle() == Lifecycle.New{
        UiUtility.showAlert("Incorrect Job Status", message: "The Job status is New. Use the scan button at the bottom of the screen to scan/add items for a new job. This option can only be used to add items after initial job signoff.", presenter: self)
      } else{
        if self.canScan{
          self.readerVC.messageLabel.text = "Point camera at a QRC Code"
          //codeReaderViewController.messageLabel.text = "Point camera at a QRC Code "
          self.allowItemAddOutsideNew = true;
          self.launchScanActivity()
        } else {
          UiUtility.showAlert("Cannot Access Scanner", message: "You must enable location services in order to use the scanner.", presenter: self)
        }
      }
    })
    

    
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in
      self.cancel()
    })
    
    alertController.addAction(logoutAction)
    alertController.addAction(aboutAction)
    alertController.addAction(printAction)
    alertController.addAction(newItemOverride)
    alertController.addAction(cancelAction)
    
    alertController.popoverPresentationController?.barButtonItem = settings; 
    present(alertController, animated: true, completion: nil)
    
  }
  
  func cancel(){
    // nothing to do
  }
  
  func about(){
    
    let delegate = UIApplication.shared.delegate as! AppDelegate;
    
    let user = delegate.currentUser;
    
    
    var aboutMessage = "Version: " + Bundle.main.releaseVersionNumber!
      +  "\n" + "Build: " + Bundle.main.buildVersionNumber!
    
    if user != nil{
      let role = delegate.userCompanyAssignment?.role
      let username = (user?.firstName)! + " " + (user?.lastName)!
      aboutMessage += "\nLogged in as " + username + "\nRole: " + role!
    }
    UiUtility.showAlert("About", message: aboutMessage, presenter: self)
  }
  
  func logout(){
    do{
      try FIRAuth.auth()?.signOut()
    } catch {
      print("logout failed");
    }
    
  }

  func launchPrintSignature(){
    
    
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "PrintViewController")) as! PrintViewController;
    
    vc.companyKey = companyKey;
    vc.jobKey = jobKey
    //vc.modalPresentationStyle = .fullScreen
    //vc.modalTransitionStyle = .coverVertical
     //present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
    
    //self.present(vc, animated: true, completion: nil)
    
    self.navigationController?.pushViewController(vc, animated: true);
  }
  
  

  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
    currentLocation = manager.location?.coordinate;
    
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
    
  }
  
  

 }





