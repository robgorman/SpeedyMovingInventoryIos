//
//  NewItemViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/3/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase
import Alamofire

class ImageItem {
  let dateKey : String
  let stringUri : String
  
  init (dateKey : String, stringUri : String){
    self.dateKey = dateKey
    self.stringUri = stringUri
  }
}

class EditItemViewController : ResponsiveTextFieldViewController,  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var buttonCategory: UIButton!
  @IBOutlet weak var buttonPackedBy: UIButton!

  @IBOutlet weak var isBoxButton: UISwitch!
  @IBOutlet weak var textViewDescription: UITextView!
  @IBOutlet weak var sliderValue: UISlider!
  @IBOutlet weak var sliderPads: UISlider!
  @IBOutlet weak var sliderVolume: UISlider!
  @IBOutlet weak var sliderWeight: UISlider!
  @IBOutlet weak var switchSync: UISwitch!
  @IBOutlet weak var textViewSpecialHandling: UITextView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var labelValue: UILabel!
  @IBOutlet weak var labelPads: UILabel!
  @IBOutlet weak var labelVolume: UILabel!
  @IBOutlet weak var labelWeight: UILabel!
  @IBOutlet weak var labelNoPhotos: UILabel!
  
// the two items below must be provided by caller
  var jobKey : String!
  var qrcCode : String!
  
  var imageItems : [ImageItem] = [];
  var itemRef : FIRDatabaseReference!
  var qrcListRef : FIRDatabaseReference!
  var item : Item!
  
  
  
  var syncWeightAndVolume : Bool = true;
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    itemRef.observe(FIRDataEventType.value, with:{(snapshot) in
      if !snapshot.exists(){
        let item = self.createNewItem()
        self.itemRef.setValue(item.asFirebaseObject());
        self.qrcListRef.setValue(self.jobKey)
      } else {
        self.item = Item(snapshot)
        self.updateFromItem()
      }
      
    })
  }
  
  func createNewItem() -> Item{
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var category = delegate.currentCategory;
    if category == nil{
      category = Category.Bedroom1
      delegate.currentCategory = category
    }
    let user  = delegate.currentUser
    
    let item = Item(category: category!, numberOfPads: 0, uidOfCreator: (user?.uid)!, desc: "", monetaryValue: 20, weightLbs: 5.0, volume: 1.0, specialHandling: "", jobKey: jobKey, packedBy: .Owner, isBox: false)
    
    //item.category = category
    //item.numberOfPads = 0;
    //item.
    return item;
    
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    item.desc = textViewDescription.text
    item.specialHandling = textViewSpecialHandling.text
    itemRef.setValue(item.asFirebaseObject())
    itemRef.cancelDisconnectOperations()
    qrcListRef.setValue(jobKey);
  }
  
  override func viewDidLoad(){
    super.viewDidLoad()
    itemRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items/" + qrcCode)
    qrcListRef = FIRDatabase.database().reference(withPath:"qrcList/")
    setupSliders()
  }
  
  func setupSliders(){
    setupValueSlider()
    setupPadsSlider()
    setupWeightAndVolumeSliders()
  }
  
  let monetaryValues = [1, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000]
  func setupValueSlider(){
    sliderValue.minimumValue = 0;
    sliderValue.maximumValue = Float((monetaryValues.count - 1))
  }
 
  @IBAction func onSliderValueChanged(_ sender: UISlider) {
    let progress = lroundf(sender.value);
    item.setMonetaryValue(value: monetaryValues[progress])
    labelValue.text = "$" + String(monetaryValues[progress]);
  }
  
  func setupPadsSlider(){
    sliderPads.minimumValue = 0;
    sliderPads.maximumValue = 9; // 10 pads max
  }
  
  @IBAction func onSliderPadsChanged(_ sender: UISlider) {
    let progress = lroundf(sender.value);
    item.setNumberOfPads(numberOfPads: progress)
    labelPads.text = String(progress);
  }
  
  var possibleWeights : [Float] = [1, 2, 5, 10, 20, 50, 100, 200, 300, 400, 500, 700];
  func setupWeightAndVolumeSliders(){
  
    if (item != nil && item.getIsBox()){
      possibleVolumes = boxVolumes;
    } else {
      possibleVolumes = normalVolumes;
    }
  
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let lbsPerCubicFoot = Int((delegate.currentCompany?.poundsPerCubicFoot)!);
   
  
    for (i,_) in possibleVolumes.enumerated(){
      possibleWeights[i] = possibleVolumes[i] * Float(lbsPerCubicFoot!)
    }
    
    setupWeightSlider();
    setupVolumeSlider();
  }
  
  var possibleVolumes : [Float] =         [1, 3, 5, 7, 10, 20, 30, 40, 50, 60, 75, 100]
  let normalVolumes : [Float] = [1, 3, 5, 7, 10, 20, 30, 40, 50, 60, 75, 100]
  let boxVolumes : [Float] = [1.5, 3.0, 4.5, 6.0 ]
  
  func setupVolumeSlider(){
    sliderVolume.maximumValue = Float(possibleVolumes.count - 1);
    sliderVolume.minimumValue = 0;
  }
  
  func onSliderVolumeChanged(sender: UISlider , fromUser : Bool)
  {
    let progress = lroundf(sender.value)
    let cubicFeet = possibleVolumes[progress]
    item.setVolume(volume: Float(possibleVolumes[progress]));
    let styled = String(format: "%.1f", cubicFeet) + " ft3"
    // TODO superscript the 3
    if fromUser && syncWeightAndVolume == true {
      sliderWeight.value = Float(weightProgressFromVolume(cubicFeet: cubicFeet))
      onSliderWeightChanged(sender: sliderWeight, fromUser: false)
     
    }
    labelVolume.text = styled;
    item.setVolume(volume: possibleVolumes[progress]);

  }
  
  @IBAction func onSliderVolumeChanged(_ sender: UISlider) {
    onSliderVolumeChanged(sender: sender, fromUser: true);
  }
  
  func setupWeightSlider(){
    sliderWeight.minimumValue = 0
    sliderWeight.maximumValue = Float(possibleWeights.count - 1)
  }
  
  
  func onSliderWeightChanged(sender : UISlider, fromUser:Bool){
    let progress = lroundf(sender.value)
    let weight = possibleWeights[progress];
    if syncWeightAndVolume == true {
      sliderVolume.value = Float(volumeProgessFromWeight(weight: weight))
      onSliderVolumeChanged(sender: sliderVolume, fromUser: false)
    }
    labelWeight.text = String(format:"%.0f", weight) + " lbs."
    item.setWeightLbs(weightLbs: possibleWeights[progress]);

  }
  
  @IBAction func onSliderWeightChanged(_ sender: UISlider) {
    onSliderWeightChanged(sender: sender, fromUser: true)
  }

  
  func  weightProgressFromVolume(cubicFeet : Float) -> Int{
    let delegate = UIApplication.shared.delegate as! AppDelegate
  
    let lbsPerCubicFoot = Int((delegate.currentCompany?.poundsPerCubicFoot!)!);
    let pounds = cubicFeet * Float(lbsPerCubicFoot!);
  // how to convert to
    let progress = convertPoundsToProgress(pounds: pounds);
    return progress;
  }
  
  func convertCubicFeetToProgess( cubicFeet : Float) -> Int{
    for (i, next) in possibleVolumes.enumerated(){
      if next > cubicFeet {
        let delta1 =  Swift.abs(next - cubicFeet);
        if i == 0 {
          return i
        }
        let delta2 = Swift.abs(next - cubicFeet);
        if delta1 < delta2 {
          return i
        } else {
          return i-1
        }
      }
    }
    return possibleVolumes.count - 1;
  }
  
  func convertPoundsToProgress(pounds: Float) -> Int{
    for (i,next) in possibleWeights.enumerated()
    {
      if next > pounds{
        let delta1 = Swift.abs(next - pounds);
        if (i == 0){
          return i;
        }
        let delta2 = Swift.abs(next - possibleWeights[i-1] );
  
        if (delta1 < delta2){
          return i;
        } else {
          return i-1;
        }
      }
    }
  
    return possibleWeights.count - 1;
  }
  
  
  func volumeProgessFromWeight(weight : Float) -> Int{
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let lbsPerCubicFoot = Int((delegate.currentCompany?.poundsPerCubicFoot)!);
    let cubicFeet = weight / Float(lbsPerCubicFoot!);
    // how to convert to
    let progress = convertCubicFeetToProgess(cubicFeet: cubicFeet);
    return progress;
  }
  
  func isClose(left : Float, right : Float) -> Bool{
    if Swift.abs(left - right) < 0.4 {
      return true;
    }
    return false;
  }
  
  func indexOf(floatArray :[Float], floatValue : Float) -> Int{
    for (i, next) in floatArray.enumerated(){
      if isClose(left: next, right: floatValue) {
        return i
      }
    }
    return 0
  }
  
  func indexOf(intArray :[Int], intValue : Int) -> Int{
     for (i, next) in intArray.enumerated(){
      if next == intValue {
       return i;
      }
    }
    return 0
  }
  func updateFromItem(){
    
    // extract the images
  
    imageItems = [];
    for (key, value) in item.imageReferences!{
      let stringkey = key as! String;
      let stringValue = value as! String;
      imageItems.append(ImageItem(dateKey: stringkey, stringUri: stringValue))
    }
    
    syncWeightAndVolume = item.getSyncWeightAndVolume()
    switchSync.isOn = syncWeightAndVolume;
    
    textViewDescription.text = item.desc!
    buttonCategory.setTitle(item.category! + "  >", for: .normal)
    buttonPackedBy.setTitle(item.packedBy!  + "  >", for: .normal)
    
    var index = indexOf(intArray: monetaryValues, intValue: item.getMonetaryValue())
    sliderValue.setValue(Float(index), animated: true)
    sliderValue.sendActions(for: .valueChanged)

    sliderPads.setValue(Float(item.getNumberOfPads()), animated :true)
    sliderPads.sendActions(for: .valueChanged)
    
    
    index = indexOf(floatArray: possibleVolumes, floatValue: item.getVolume())
    sliderVolume.setValue(Float(index), animated:true)
    sliderVolume.sendActions(for: .valueChanged)
    
    index = indexOf(floatArray: possibleWeights, floatValue: item.getWeightLbs())
    sliderWeight.setValue(Float(index), animated:true)
    sliderWeight.sendActions(for: .valueChanged)
    
    textViewSpecialHandling.text = item.specialHandling
    
    isBoxButton.isOn = item.getIsBox()
    
    
    handleControlVisibility(imageItems.count)
    collectionView.reloadData()
  }
  
  class CategoryCallback : IndexSelected{
    var outer : EditItemViewController
    init(vc : EditItemViewController){
      outer = vc;
    }
    func indexSelected(index: Int) {
      let category = Category.allValues[index]
      
      FIRDatabase.database().reference(withPath:"itemlists/" + outer.jobKey + "/items/" + outer.qrcCode + "/category").setValue(category.rawValue)
      
       let delegate = UIApplication.shared.delegate as! AppDelegate
      delegate.currentCategory = category;

    }
  }
  
  @IBAction func categoryPressed(_ sender: AnyObject) {
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SpinnerViewController")) as! SpinnerViewController;
    
    
    var labels : [String] = [];
    for next in Category.allValues{
      labels.append(next.rawValue)
    }
    vc.labels = labels;
    
    let label = item.getCategory().rawValue;
    let i = labels.index(of: label)
    vc.selectedIndex = i!
    vc.title = "Choose a Category"
    
    vc.callback = CategoryCallback(vc: self)
    
    
    
    self.navigationController?.pushViewController(vc, animated: true);

  }
  
  
  
  
  @IBAction func onSyncChanged(_ sender: UISwitch) {
  
    syncWeightAndVolume = sender.isOn
    item.setSyncWeightAndVolume(value: sender.isOn);
  }
  
  
  class PackedByCallback : IndexSelected{
    var outer : EditItemViewController
    init(vc : EditItemViewController){
      outer = vc;
    }
    func indexSelected(index: Int) {
      let packedBy = PackedBy.allValues[index]
      
      FIRDatabase.database().reference(withPath:"itemlists/" + outer.jobKey + "/items/" + outer.qrcCode + "/packedBy").setValue(packedBy.rawValue)
      
    }
  }

  @IBAction func packedByPressed(_ sender: AnyObject) {
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SpinnerViewController")) as! SpinnerViewController;
    
    
    var labels : [String] = [];
    for next in PackedBy.allValues{
      labels.append(next.rawValue)
    }
    vc.labels = labels;
    
    let label = item.getPackedBy().rawValue;
    let i = labels.index(of: label)
    vc.selectedIndex = i!
    vc.title = "Choose PackedBy"
    
    vc.callback = PackedByCallback(vc: self)
    
    
    
    self.navigationController?.pushViewController(vc, animated: true);
  }
  
 
 
  
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
      labelNoPhotos.isHidden = false;
      collectionView.isHidden = true;
    } else {
      labelNoPhotos.isHidden = true;
     collectionView.isHidden = false;
    }
  }
  
  // data soruce
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
    let count = imageItems.count;
    return count
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let cellWidth = collectionView.bounds.size.width/3.5;
    print(cellWidth)
    let cellHeight = cellWidth
    print(cellHeight)
    return CGSize(width: cellWidth, height: cellHeight);
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
    
    let _ = imageRef.putFile( filename, metadata: metadata) { metadata, error in
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
  
  @IBAction func isBoxPressed(_ isBox: UISwitch) {
    item.setIsBox(value: isBox.isOn)
  }

}




