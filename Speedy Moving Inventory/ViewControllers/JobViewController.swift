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



class JobViewController : UIViewController, QRCodeReaderViewControllerDelegate {
  
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var summaryView: UIView!
  @IBOutlet weak var detailsView: UIView!
  
  @IBOutlet weak var labelEmail: UILabel!
  @IBOutlet weak var labelLifecycle: UILabel!
  
  @IBOutlet weak var labelPhone: UILabel!
  @IBOutlet weak var labelSit: UILabel!
  @IBOutlet weak var labelScanned: UILabel!
  
  var jobKey : String!  // caller will provide
  var jobRef : FIRDatabaseReference!;
  
  var itemsRef : FIRDatabaseReference!
  var itemsMap : [String : Item] = [:];
  
  var job : Job!
  var jobSummary : JobSummary!
  var jobDetails : JobDetails!
  
  

  var user : User!;
  
  var processingCode = false;
  // Good practice: create the reader lazily to avoid cpu overload during the
  // initialization and each time we need to scan a QRCode
  lazy var readerVC = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder {
    $0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
  })

  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.edgesForExtendedLayout = []
   // self.edgesForExtendedLayout = UIRectEdge.none
    assert(jobKey != nil)
    let delegate = UIApplication.shared.delegate as! AppDelegate
    user = delegate.currentUser;
    assert(user != nil)
    jobRef = FIRDatabase.database().reference(withPath: "joblists/" + user.companyKey! + "/jobs/" + jobKey)
    
     itemsRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items")

    labelScanned.text = "No Moving Items"
  }
  
  //DispatchQueue.global(qos: .background).async {
  //print("This is run on the background queue")
  
  ///DispatchQueue.main.async {
  //print("This is run on the main queue, after the previous code in outer block")
  //}
  //}
  
  override func viewWillAppear(_ animated: Bool) {
    Hud.on(self)
    
      self.jobRef.observe(FIRDataEventType.value, with: {(snapshot) in
        self.job = Job(snapshot)
        self.updateFromJob();
        Hud.off(self)
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
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    jobRef.cancelDisconnectOperations();
    itemsRef.cancelDisconnectOperations()
  }
  
  func updateFromJob(){
    jobSummary.jobUpdate(job)
    jobDetails.jobUpdate(job)
    labelEmail.text = job.customerEmail
    labelLifecycle.text =  job.getLifecycle().rawValue
    
    labelPhone.text = PhoneNumberFormatter.format(job.customerPhone!)
    
    labelSit.text = (job.getStorageInTransit()) ? "true" : "false"
    
    navigationItem.title = "(" + job.jobNumber! + ")"
    navigationItem.title = navigationItem.title!  + " " + job.customerFirstName! + " " + job.customerLastName!;
    
    
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
    }
  }
  
  @IBAction func scanPressed(_ sender: AnyObject) {
    // Retrieve the QRCode content
    // By using the delegate pattern
    readerVC.delegate = self
    
    // Or by using the closure pattern
    readerVC.completionBlock = { (result: QRCodeReaderResult?) in
      print(result!)
    }

    self.navigationController?.pushViewController(readerVC, animated: true)
    }
  
  // MARK: - QRCodeReaderViewController Delegate Methods
  
  //func reader(_ reader: QRCodeReader.QRCodeReaderViewController, didScanResult result: QRCodeReader.QRCodeReaderResult) {
  func reader(_ codeReaderViewContoller: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
    if processingCode{
      return;
    }
    processingCode = true
    barcodeScanned(code: result.value, codeReaderViewContoller: codeReaderViewContoller);
        //dismiss(animated: true, completion: nil)
  }
 
  
  func barcodeScanned(code : String, codeReaderViewContoller : QRCodeReaderViewController){
    if !Utility.isQrcCodeValid(code: code){
      invalidCodeUserFeedback(codeReaderViewContoller: codeReaderViewContoller);
      processingCode = false;
      return;
    }
    //codeReaderViewContoller.messageLabel.text = "Point camera at a QRC Code"
    let itemKeyRef = FIRDatabase.database().reference(withPath: "qrcList/" + code)
    
    itemKeyRef.observe(FIRDataEventType.value, with: {(snapshot) in
      if !snapshot.exists(){
        // item is new
        self.positiveFeeback(codeReaderViewContoller: codeReaderViewContoller)
        self.createNewItem(job: self.job, code: code, codeReaderViewContoller: codeReaderViewContoller)
        self.processingCode = false;
      } else {
        // item exists see if its in ths job
        let jobKey = snapshot.value as! String
        if jobKey != self.jobKey{
          self.itemBelongsToAnotherJobFeedback( codeReaderViewContoller: codeReaderViewContoller)
          self.processingCode = false;
        } else {
          self.positiveFeeback(codeReaderViewContoller: codeReaderViewContoller)
          let itemRef = FIRDatabase.database().reference(withPath: "/itemlists/" + self.jobKey + "/items/" + code)
          itemRef.observe(FIRDataEventType.value, with: {(snapshot) in
            let item = Item(snapshot)
            //TODO fix shouldn't use "New"
            if self.job.getLifecycle() == .New {
              self.editItem(job: self.job, code: code, item: item, codeReaderViewContoller:  codeReaderViewContoller)
            } else { // for any other job lifecycle just mark as scanned
              let isScanned = item.getIsScanned();
              if isScanned {
                self.alreadyScannedFeedback(codeReaderViewContoller: codeReaderViewContoller);
                
              } else {
                // set item as scanned
                FIRDatabase.database().reference(withPath: "/itemlists/" + self.jobKey + "/items/" + code ).setValue(true, forKey: "isScanned")
              }
            }
            self.processingCode = false;
          })
        }
      }
      
    })

  }
  
  
  func alreadyScannedFeedback(codeReaderViewContoller : QRCodeReaderViewController){
    codeReaderViewContoller.messageLabel.text = "This item has already been scanned."
    //playSound(file: "negative_beep_2", type: "wav");
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }
  
  
  func positiveFeeback(codeReaderViewContoller : QRCodeReaderViewController){
    Utility.playSound(file: "positive_beep", type: "wav");
  }
  func itemBelongsToAnotherJobFeedback(codeReaderViewContoller : QRCodeReaderViewController){
    codeReaderViewContoller.messageLabel.text = "This item belongs to another job."
    Utility.playSound(file: "negative_beep", type: "wav");
     AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }
  
  func createNewItem(job : Job, code : String, codeReaderViewContoller: QRCodeReaderViewController){
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
    vc.jobKey = jobKey
    vc.qrcCode = code;
    codeReaderViewContoller.navigationController?.pushViewController(vc, animated: true);
  }
  
  func editItem(job : Job, code : String, item : Item, codeReaderViewContoller: QRCodeReaderViewController){
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
    vc.jobKey = jobKey
    vc.qrcCode = code;
    codeReaderViewContoller.navigationController?.pushViewController(vc, animated: true);
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
    let role = user.getRole()
    if role == Role.AgentCrewMember || role == Role.CrewMember || role == Role.Customer {
      UiUtility.showAlert("Not Authorized", message: "Your role must be Foreman or greater in order to signoff.", presenter: self)
    }else {
      let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SignOffViewController")) as! SignOffViewController;
    
      self.navigationController?.pushViewController(vc, animated: true);
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
    let lifecycle = job.getLifecycle()
    if lifecycle == Lifecycle.Delivered{
      UiUtility.showAlert("Job is Complete", message: "The Job is complete. No further signnoff is possible", presenter: self)
      return;
    }
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let user = delegate.user;
    let role = user?.getRole()
    
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
  
 }





