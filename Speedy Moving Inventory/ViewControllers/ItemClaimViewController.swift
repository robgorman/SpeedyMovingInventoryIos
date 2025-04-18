//
//  ItemClaimViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/5/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Foundation
import Firebase
import AVFoundation
import AudioToolbox
import CoreLocation

class ItemClaimViewController : UIViewController, UITextFieldDelegate, UITextViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
  UIImagePickerControllerDelegate, UINavigationControllerDelegate,
  CLLocationManagerDelegate, ScannerViewControllerDelegate{
  
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var numberOfPadsLabel: UILabel!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var packedByLabel: UILabel!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var weightLabel: UILabel!
  @IBOutlet weak var isBoxLabel: UILabel!
  @IBOutlet weak var isDamagedSwitch: UISwitch!
  @IBOutlet weak var claimNumberTextField: UITextField!
  @IBOutlet weak var damageDescriptionTextView: UITextView!
  @IBOutlet weak var preexistingDamageTextView: UITextView!
  @IBOutlet weak var preexistingImageView: UIImageView!
  @IBOutlet weak var imageCollectionView: UICollectionView!
  @IBOutlet weak var takePictureButton: UIButton!
  // the two items below must be provided by caller
  @IBOutlet weak var disassembledLabel: UILabel!
  @IBOutlet weak var noPhotosLabel: UILabel!
  @IBOutlet weak var scanOverrideSwitch: UISwitch!
  @IBOutlet weak var photosLoadingIndicator: UIActivityIndicatorView!
  
  lazy var readerVC = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder {
    var o = $0
    o.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
  })

  // lifecycle is a param
  var lifecycle :Lifecycle!
  var jobKey : String!
  var qrCode : String!
  
  var imageItems : [ImageItem] = [];
  var itemRef : FIRDatabaseReference!
  var item : Item!

  var isLoadingFirstTime : Bool = true;
  
  let locationManager = CLLocationManager();
  var currentLocation : CLLocationCoordinate2D?
  var canScan = false;

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    itemRef.observe(FIRDataEventType.value, with:{(snapshot) in
      self.isLoadingFirstTime = false;
      self.enableUserInterface();
      if !snapshot.exists(){
        // this is an error
      } else {
        self.item = Item(snapshot)
        self.updateValuesFromItem()
      }
      
    })
    
    
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
  }

  func updateItemFromControls(){
    item.claimNumber = claimNumberTextField.text
    item.damageDescription = damageDescriptionTextView.text
    
    if item.getIsScanned() == false && scanOverrideSwitch.isOn{
      // we have a manual scan
      var latitude = 0.0;
      var longitude = 0.0;
      if self.currentLocation != nil{
        latitude = (self.currentLocation?.latitude)!
        longitude = (self.currentLocation?.longitude)!;
      }
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      let scanRecord = ScanRecord(scanDateTime: Date(), latitude: latitude, longitude: longitude, uidOfScanner: (appDelegate.currentUser?.uid)!,isScanOverride: true, lifecycle: self.lifecycle);
      let ref = FIRDatabase.database().reference(withPath: "/scanHistory/" + qrCode).childByAutoId()
      ref.setValue(scanRecord.asFirebaseObject())

    }
    item.setIsScanned(value: scanOverrideSwitch.isOn)
    item.setHasClaim(value:   isDamagedSwitch.isOn)
    itemRef.setValue(item.asFirebaseObject())
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // TODO pull data the save
    if item != nil{
      updateItemFromControls()
    }
   
    itemRef.removeAllObservers()
    locationManager.stopUpdatingLocation();
  }
  
  var settings : UIBarButtonItem?
  
  override func viewDidLoad(){
    super.viewDidLoad()
    
    // TODO the settings menu should allow QRC code replacement, but its not working yet
    let settings = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(ItemClaimViewController.settingsPressed))
    
    self.navigationItem.rightBarButtonItem = settings

    itemRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items/" + qrCode)
    
    claimNumberTextField.layer.borderColor = Colors().speedyLight.cgColor;
    claimNumberTextField.layer.borderWidth = 1.0
    
    damageDescriptionTextView.layer.borderColor = Colors().speedyLight.cgColor;
    damageDescriptionTextView.layer.borderWidth = 1.0

    isLoadingFirstTime = true;
    handleControlVisibility(0);
    
    setTitle(code: qrCode)
    
  }
  
  func setTitle(code : String){
    let dummy = "01234";
    let range = dummy.startIndex..<dummy.endIndex
    let substring = code.substring(with: range)
    navigationItem.title = "# " + substring
  }
  
  func settingsPressed(){
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let replaceQrcAction = UIAlertAction(title: "Re-Assign QRC", style: .default, handler: {(action) in
      self.reassignQrc();
    })
    
    alertController.addAction(replaceQrcAction)
    
    let presenter = alertController.popoverPresentationController;
    presenter?.barButtonItem = settings;
    present(alertController, animated: true, completion: nil)
  }
  
  func updateValuesFromItem(){
    
    // extract the images
    imageItems = [];
    for (key, value) in item.imageReferences!{
      let stringkey = key as! String;
      let stringValue = value as! String;
      imageItems.append(ImageItem(dateKey: stringkey, stringUri: stringValue))
    }

    descriptionTextView.text = item.desc
    
        
    if item.getHasPreexistingDamage(){
      preexistingDamageTextView.text = item.preexistingDamageDescription
      preexistingImageView.isHidden = false;
    } else {
      preexistingDamageTextView.text = "None";
      preexistingImageView.isHidden = true;
    }
   
    valueLabel.text = "$" + String(format:"%.2f", item.getMonetaryValue())
    numberOfPadsLabel.text = String(item.getNumberOfPads());
    categoryLabel.text = item.getCategory().rawValue
    packedByLabel.text = item.getPackedBy().rawValue
    let s = String(format:"%.1f", item.getVolume()) + " ft3"
    volumeLabel.attributedText = TextUtils.formFt3Superscript(text: s)
    weightLabel.text = String(format:"%.0f", item.getWeightLbs()) + " lbs."
    isBoxLabel.text = item.getIsBox() ? "Yes" : "No"
    disassembledLabel.text = item.getIsDisassembled() ? "Yes" : "No"
    isDamagedSwitch.isOn = item.getHasClaim()
    claimNumberTextField.text = item.claimNumber
    damageDescriptionTextView.text = item.damageDescription
    
    handleControlVisibility(imageItems.count)
    imageCollectionView.reloadData()
    scanOverrideSwitch.isOn = item.getIsScanned()
  }
  
  @IBAction func takePicturePressed(_ sender: AnyObject) {
    if UIImagePickerController.isSourceTypeAvailable(
      UIImagePickerControllerSourceType.camera) {
      
      let imagePicker = UIImagePickerController()
      
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerControllerSourceType.camera
     
      imagePicker.allowsEditing = false
      
      self.present(imagePicker, animated: true, completion: nil)
    }
  }
  
  func maxOf(x : Float, y: Float) -> Float{
    if x > y {
      return (x);
    }
    return (y);
  }
  
  func resizeImage(image: UIImage, largestDim: Float) -> UIImage {
    var newWidth : Float = 0.0
    var newHeight : Float = 0.0
    let width : Float = Float(image.size.width);
    let height : Float = Float(image.size.height);
    
    let maxDimension = maxOf(x: width, y: height)
    if maxDimension > largestDim {
      if width > height {
        newWidth = largestDim
        newHeight = Float(height) * (largestDim / Float(width))
      } else {
        newHeight = largestDim
        newWidth = Float(width) * (largestDim / Float(height))
      }
    }

    UIGraphicsBeginImageContext(CGSize(width: CGFloat(newWidth), height:CGFloat(newHeight)))
    image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(newWidth), height: CGFloat(newHeight)))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }

  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  func genNonCollisionFileName() -> String{
    let time = Date().timeIntervalSince1970
    return String(time) + ".jpg"
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
    var image = info[UIImagePickerControllerOriginalImage] as! UIImage
    image = resizeImage(image: image, largestDim: 800.0)
    
    let data = UIImageJPEGRepresentation(image, 0.5)
    let filename = getDocumentsDirectory().appendingPathComponent(genNonCollisionFileName())

    try? data?.write(to: filename)
    
    let now = Date().timeIntervalSince1970
    let milliseconds = now * 1000; // get milliseconds
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let companyKey = delegate.userCompanyAssignment?.companyKey
    
    let storage = FIRStorage.storage()
    let timeStampString = String(format:"%.0f", milliseconds)
    let payloadPart1 = "images/" + companyKey! + "/" + jobKey
    let payload = payloadPart1 + "/" + qrCode + "/" + timeStampString;
    let imageRef = storage.reference().child(payload)
    // Upload the file to the path "images/rivers.jpg"
    
    let metadata = FIRStorageMetadata()
    metadata.contentType = "image/jpeg"

    _ = imageRef.putFile( filename, metadata: metadata) { metadata, error in
      if (error != nil) {
        // Uh-oh, an error occurred!
        // TODO delete the file
        // not sure what to do
        // TODO how to handle erorr
      } else {
        // Metadata contains file metadata such as size, content-type, and download URL.
        let downloadURL = metadata!.downloadURL()
        
        //var s = downloadURL
       // let downloadUrlString = String(downloadURL)
        let s = downloadURL?.absoluteString
        self.item.imageReferences?[timeStampString] = s
        self.itemRef.child("imageReferences").setValue(self.item.imageReferences)
      }
      self.removeFile(filename: filename)
    }
    picker.dismiss(animated: true, completion: nil)
  }
  
  func removeFile(filename : URL){
    do{
      try FileManager.default.removeItem(at: filename)
    } catch {
      print("file delete failed");
    }
  }
  
  /// text field delegate
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool // return NO to disallow editing.
  {
    return true;
  }
  func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
  {
    //super.textFieldDidBeginEditing(textField)
    //self.activeText = textField;
  }
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
  {
    return true;
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
  {
    textField.resignFirstResponder()
    return true;
  }
  
  func handleControlVisibility(_ imageCount : Int){
    if isLoadingFirstTime{
      photosLoadingIndicator.isHidden = false;
      noPhotosLabel.isHidden = true;
      imageCollectionView.isHidden = true;
    } else {
       photosLoadingIndicator.isHidden = true;
      if imageCount == 0 {
        noPhotosLabel.isHidden = false;
        imageCollectionView.isHidden = true;
      } else {
        noPhotosLabel.isHidden = true;
        imageCollectionView.isHidden = false;
      }
    }
  }
  // data source
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
    let count = imageItems.count;
    return count
  }
  
  // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemDetailsImageCell", for: indexPath) as!
    ItemDetailsImageCell;
    
    let imageItem = imageItems[indexPath.row];
    
    loadImage( imageItem.stringUri, cell: cell)
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    let dateNumeric = numberFormatter.number(from: imageItem.dateKey)
    let date = Utility.convertNsNumberToDate(rawValue: dateNumeric)
    
    let formatter = DateFormatter()
    formatter.dateFormat = "mm/dd/yy hh:mm a "
    cell.imageDate.text = formatter.string(from: date);
    return cell;
    
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    // TODO this should range from 3 to 5 depending on device screen size
    let cellWidth = collectionView.bounds.size.width/3 - 2;
    print(cellWidth)
    let cellHeight = cellWidth 
    print(cellHeight)
    return CGSize(width: cellWidth, height: cellHeight);
  }
  
  func loadImage(_ imageUri : String, cell : ItemDetailsImageCell) {
    
    let url = URL(string: imageUri)
    cell.itemImageView.af_setImage(withURL: url!, placeholderImage : UIImage(named:"loading"));
  }

  @IBAction func scanOverridePressed(_ sender: AnyObject) {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let role = delegate.userCompanyAssignment?.getRole();
    if role == Role.AgentCrewMember || role == Role.CrewMember || role == Role.Customer {
      UiUtility.showAlert("Not Authorized", message: "Your role must be Foreman or greater in order to override the scanner.", presenter: self)
    } else {
      Utility.playSound(file: "success", type: "mp3");
      AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
      updateItemFromControls()
    }
  }
  
  @IBAction func onDamageSwitchChanged(_ sender: UISwitch) {
    updateItemFromControls()
  }
  func enableUserInterface(){
    isDamagedSwitch.isEnabled = true;
    claimNumberTextField.isEnabled = true;
    scanOverrideSwitch.isEnabled = true;
    damageDescriptionTextView.isEditable = true;
    takePictureButton.isEnabled = true;
    
  }
  
  func reassignQrc(){
    launchScanActivity();
  }
  
  func launchScanActivity(){
    if lifecycle == Lifecycle.Delivered{
      UiUtility.showAlert("Job is Complete", message: "The Job is complete. No further scanning is possible", presenter: self)
      return;
    }
    
    // var readerVC = read from storyboard
    let readerVC = (self.storyboard?.instantiateViewController(withIdentifier: "ScannerViewController"))
      as! ScannerViewController;
    
    // Retrieve the QRCode content
    // By using the delegate pattern
    readerVC.delegate = self
    // Or by using the closure pattern
    readerVC.completionBlock = { (result: ScannerResult?) in
      if result != nil{
        print(result!)
      }
    }
    readerVC.prompt = "Point Camera at Replacement QR Code"
    self.navigationController?.pushViewController(readerVC, animated: true)
  }

  func cancel(){
    // nothing to do
  }
  // MARK: - QRCodeReaderViewController Delegate Methods
  func reader(_ scannerViewController: ScannerViewController, didScanResult result: ScannerResult) {
    barcodeScanned(newCode: result.value, scannerViewController: scannerViewController)
  }
  
  func readerDidCancel(_ reader: ScannerViewController) {
    reader.dismiss(animated: true, completion: nil)
  }
  
  func invalidCodeUserFeedback(scannerViewController : ScannerViewController, message : String){
    var soundId : SystemSoundID = 0;
    let filePath = Bundle.main.path(forResource: "negative_beep", ofType: "wav")
    let soundURL = NSURL(fileURLWithPath: filePath!)
    
    AudioServicesCreateSystemSoundID(soundURL, &soundId)
    AudioServicesPlaySystemSound(soundId)
    
    scannerViewController.messageLabel.text = message
  }
  
  func barcodeScanned(newCode : String, scannerViewController : ScannerViewController){
    if !Utility.isQrcCodeValid(code: newCode){
      invalidCodeUserFeedback(
        scannerViewController : scannerViewController,
                     message  : "Invalid QR Code -- Not a Speedy Moving Inventory Code");
      return;
    }
    let newQrCode = FIRDatabase.database().reference(withPath: "qrcList/" + newCode)
    
    newQrCode.observeSingleEvent(of: .value, with: {(snapshot) in
      if snapshot.exists(){
        self.invalidCodeUserFeedback(
          scannerViewController : scannerViewController,
          message  : "QR Code is already in use.");
        scannerViewController.showNext()
       } else {
        newQrCode.setValue(self.jobKey, withCompletionBlock: {(databaseError, databaseReference) in
          self.itemRef.removeAllObservers();
          self.itemRef = FIRDatabase.database().reference(withPath:"itemlists/" + self.jobKey + "/items/" + newCode)
          let oldQrCode = FIRDatabase.database().reference(withPath:"qrcList/" + self.qrCode)
          oldQrCode.removeValue()
          
          let oldItemReference = FIRDatabase.database().reference(withPath:"itemlists/" + self.jobKey + "/items/" + self.qrCode)
          oldItemReference.removeValue()
          self.itemRef.setValue(self.item.asFirebaseObject());
          
          scannerViewController.endScan();
          
          // post a message that the code has been reassigned
          
          let deadlineTime = DispatchTime.now() + .milliseconds(500)
          DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            UiUtility.showAlert("QR Code Reassigned", message: "The QR Code has been sucessfully reassigned.", presenter: self)
          }
          self.setTitle(code: newCode)
        })
      }
    })
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
    currentLocation = manager.location?.coordinate;
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
    
  }
}
