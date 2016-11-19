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

class ItemClaimViewController : ResponsiveTextFieldViewController,  UICollectionViewDataSource, UICollectionViewDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate{
  
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
  @IBOutlet weak var imageCollectionView: UICollectionView!
  @IBOutlet weak var takePictureButton: UIButton!
  // the two items below must be provided by caller
  @IBOutlet weak var noPhotosLabel: UILabel!
  @IBOutlet weak var scanOverrideSwitch: UISwitch!
  var jobKey : String!
  var qrcCode : String!
  
  var imageItems : [ImageItem] = [];
  var itemRef : FIRDatabaseReference!
  var item : Item!


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    itemRef.observe(FIRDataEventType.value, with:{(snapshot) in
      if !snapshot.exists(){
        // this is an error
      } else {
        self.item = Item(snapshot)
        self.updateFromItem()
      }
      
    })
  }

  func updateDatabase(){
    item.claimNumber = claimNumberTextField.text
    item.damageDescription = damageDescriptionTextView.text
    item.setIsScanned(value: scanOverrideSwitch.isOn)
    itemRef.setValue(item.asFirebaseObject())

  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // TODO pull data the save
    updateDatabase()
   
    itemRef.cancelDisconnectOperations()

  }
  
  override func viewDidLoad(){
    super.viewDidLoad()
    itemRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items/" + qrcCode)
  }
  
  func updateFromItem(){
    
    // extract the images
    
    imageItems = [];
    for (key, value) in item.imageReferences!{
      let stringkey = key as! String;
      let stringValue = value as! String;
      imageItems.append(ImageItem(dateKey: stringkey, stringUri: stringValue))
    }

    descriptionTextView.text = item.desc
    valueLabel.text = "$" + String(item.getMonetaryValue())
    numberOfPadsLabel.text = String(item.getNumberOfPads());
    categoryLabel.text = item.getCategory().rawValue
    packedByLabel.text = item.getPackedBy().rawValue
    volumeLabel.text = String(format:"%.1f", item.getVolume()) + " ft3"
    weightLabel.text = String(format:"%.0f", item.getWeightLbs()) + " lbs."
    isBoxLabel.text = item.getIsBox() ? "Yes" : "No"
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
    let companyKey = delegate.currentUser?.companyKey
    
    let storage = FIRStorage.storage()
    let timeStampString = String(format:"%.0f", milliseconds)
    let payloadPart1 = "images/" + companyKey! + "/" + jobKey
    let payload = payloadPart1 + "/" + qrcCode + "/" + timeStampString;
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
  
//  func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafePointer<Void>) {
//    
//    if error != nil {
//      let alert = UIAlertController(title: "Save Failed",
//                                    message: "Failed to save image",
//                                    preferredStyle: UIAlertControllerStyle.Alert)
//      
//      let cancelAction = UIAlertAction(title: "OK",
//                                       style: .Cancel, handler: nil)
//      
//      alert.addAction(cancelAction)
//      self.presentViewController(alert, animated: true,
//                                 completion: nil)
//    }
//  }
//  
  
  /// text field delegate
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool // return NO to disallow editing.
  {
    return true;
  }
  override func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
  {
    super.textFieldDidBeginEditing(textField)
    //self.activeText = textField;
  }
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
  {
    return true;
  }
  
  override func textFieldDidEndEditing(_ textField: UITextField) // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
  {
    super.textFieldDidEndEditing(textField)
  }
  
  
  override func textViewDidBeginEditing(_ textView: UITextView)
  {
    super.textViewDidBeginEditing(textView)
    //activeText = textView
  }
  
  override func textViewDidEndEditing(_ textView: UITextView)
  {
    super.textViewDidEndEditing(textView)
    
  }
  
  
  func textField(_ textField: UITextField,
                 shouldChangeCharactersInRange range: NSRange,
                 replacementString string: String) -> Bool{
    if string.characters.count == 0{
      return true;
    }
    return true;
  }
  
  
  override func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
  {
    textField.resignFirstResponder()
    return true;
  }
  
  func handleControlVisibility(_ imageCount : Int){
    if imageCount == 0 {
      noPhotosLabel.isHidden = false;
      imageCollectionView.isHidden = true;
    } else {
      noPhotosLabel.isHidden = true;
      imageCollectionView.isHidden = false;
    }
  }
  // data soruce
  
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
  
  func loadImage(_ imageUri : String, cell : ItemDetailsImageCell) {
    
    let url = URL(string: imageUri)
    do {
      let uiImage = try UIImage(data: Data(contentsOf: url!));
      cell.itemImageView.image = uiImage;
    } catch {
      cell.itemImageView.image = UIImage(named:"noimage");
    }
  }

  @IBAction func scanOverridePressed(_ sender: AnyObject) {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let user = delegate.currentUser;
    let role = user?.getRole();
    if role == Role.AgentCrewMember || role == Role.CrewMember || role == Role.Customer {
      UiUtility.showAlert("Not Authorized", message: "Your role must be Foreman or greater in order to override the scanner.", presenter: self)
    } else {
      Utility.playSound(file: "positive_beep", type: "wav");
      updateDatabase()
    }
   
  }
}
