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

class SliderRange{
  var low : Float!
  var high : Float!
  var inc  : Float!
  init( low: Float, high : Float, inc : Float){
    self.low = low;
    self.high = high;
    self.inc = inc;
  }
}

class EditItemViewController : UIViewController,  UITextViewDelegate,  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIGestureRecognizerDelegate,
    IItemDeletePressed
{

  @IBOutlet weak var buttonCategory: UIButton!
  @IBOutlet weak var buttonPackedBy: UIButton!

  @IBOutlet weak var pickButton: UIButton!
  
  @IBOutlet weak var textViewDescription: UITextView!
  @IBOutlet weak var damageDescription: UITextView!
  // @IBOutlet weak var sliderValue: UISlider!
  @IBOutlet weak var sliderPads: UISlider!
  @IBOutlet weak var sliderVolume: UISlider!
  @IBOutlet weak var sliderWeight: UISlider!
  
  @IBOutlet weak var labelLbsPerFt3: UILabel!
   @IBOutlet weak var switchIsBox: UISwitch!
  @IBOutlet weak var switchSync: UISwitch!
  
  @IBOutlet weak var switchDisassembled: UISwitch!
  @IBOutlet weak var textViewSpecialHandling: UITextView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var labelValue: UILabel!
  @IBOutlet weak var labelPads: UILabel!
  @IBOutlet weak var labelVolume: UILabel!
  @IBOutlet weak var labelWeight: UILabel!
  @IBOutlet weak var labelNoPhotos: UILabel!
  
  @IBOutlet weak var photosLoadingIndicator: UIActivityIndicatorView!
  @IBOutlet weak var padsRow: UIView!
// the three items below must be provided by caller
  var jobKey : String!
  var qrcCode : String!
  var companyKey : String!
  var itemWasCreatedOutOfPhase : Bool!
  
  var imageItems : [ImageItem] = [];
  var itemRef : FIRDatabaseReference!
  var qrcListRef : FIRDatabaseReference!
  var item : Item!
  
  var activeTextView: UITextView?;
  
  var syncWeightAndVolume : Bool = true;
  
  var poundsPerCubicFeet : Int!;
  
  var pickLaunched = false;
  
  var isLoadingFirstTime : Bool = true;
  var deleteMode = false;
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
      itemRef.observe(FIRDataEventType.value, with:{(snapshot) in
        self.isLoadingFirstTime = false;
        self.enableUserInterface()
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
    
    let item = Item(category: category!, numberOfPads: 0, uidOfCreator: (user?.uid)!, desc: "",
                    monetaryValue: Utility.monetaryValueFromWeight(weight: 5.0),
                    weightLbs: 5.0, volume: 1.0, specialHandling: "", jobKey: jobKey, packedBy: .Owner, isBox: false,
                    itemWasCreatedOutOfPhase : itemWasCreatedOutOfPhase,
                    createDateTime: Date())
    
    //item.category = category
    //item.numberOfPads = 0;
    //item.
    return item;
    
  }
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if item != nil{
      item.desc = textViewDescription.text
      item.damageDescription = damageDescription.text;
      item.specialHandling = textViewSpecialHandling.text
      itemRef.setValue(item.asFirebaseObject())
      
    }
   
    itemRef.removeAllObservers()
    qrcListRef.setValue(jobKey);
    qrcListRef.removeAllObservers()
  }
  
    
  
  override func viewDidLoad(){
    super.viewDidLoad()
    itemRef = FIRDatabase.database().reference(withPath:"itemlists/" + jobKey + "/items/" + qrcCode)
    qrcListRef = FIRDatabase.database().reference(withPath:"qrcList/" + qrcCode)
    setupSliders()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let text =  "(" + (appDelegate.currentCompany?.poundsPerCubicFoot)! + " lbs/ft3)";
    
    // TODO for ft3
    let attString = TextUtils.formFt3Superscript(text: text);
    labelLbsPerFt3.attributedText = attString;
    labelLbsPerFt3.text = text;
    poundsPerCubicFeet = Int((appDelegate.currentCompany?.poundsPerCubicFoot)!)
    
    textViewDescription.layer.borderColor = Colors().speedyLight.cgColor
    textViewDescription.layer.borderWidth = 1.0
    
    damageDescription.layer.borderColor = Colors().speedyLight.cgColor
    damageDescription.layer.borderWidth = 1.0
    
    textViewSpecialHandling.layer.borderColor = Colors().speedyLight.cgColor;
    textViewSpecialHandling.layer.borderWidth = 1.0
    isLoadingFirstTime = true;
    handleControlVisibility(0);
    
    
    let longPressGestureRecogizer = UILongPressGestureRecognizer(
      target : self,
      action: #selector(self.handleLongPress(gestureRecognizer:)))
    
    longPressGestureRecogizer.minimumPressDuration = 0.5;
    longPressGestureRecogizer.delegate = self;
    longPressGestureRecogizer.delaysTouchesBegan = true;
    self.collectionView.addGestureRecognizer(longPressGestureRecogizer);
    
    let dummy = "01234";
    let range = dummy.startIndex..<dummy.endIndex
    let substring = qrcCode.substring(with: range)
    navigationItem.title = "Item: " + substring
    

  }

  
  func handleBeginDeleteMode(){
    self.deleteMode = true;
    collectionView.reloadData();
  }
  
  func handleEndDeleteMode(){
    deleteMode = false;
    collectionView.reloadData();
  }
  
  func deleteItem(_ indexPath : Int){
  
    let imageItem = imageItems[indexPath]
    // how to delete an item?
    removeItem(companyKey: companyKey, jobKey: jobKey, itemKey: qrcCode, imageKey : imageItem.dateKey, imageReferences: item.imageReferences! )
    handleEndDeleteMode();
  }
  
  func removeItem(companyKey : String, jobKey : String, itemKey : String, imageKey:String, imageReferences : NSDictionary){
    //FIRDatabase.database().reference(withPath: "/itemlists/" + jobKey + "/items/" + itemKey).removeValue();
    
    //FIRDatabase.database().reference(withPath: "/qrcList/" + itemKey).removeValue();
    FIRDatabase.database().reference(withPath: "/itemlists/" + jobKey + "/items/" + itemKey + "/imageReferences/"
      + imageKey).removeValue();

    
    let storage = FIRStorage.storage();
    let appDelegate = UIApplication.shared.delegate as! AppDelegate;
    let storageRef = storage.reference(forURL: appDelegate.storageUrl!);
    for (key, _) in imageReferences{
      let keyString = key as! String;
      if imageKey == keyString{
        var path = "/images/" + companyKey + "/";
        path = path +  jobKey + "/" + itemKey ;
        path = path + "/" + keyString
        // TODO this causes exception
        //storageRef.child(path).delete();
      }
    }
  }
  
  
  func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
    // we don't need to check lifecycle, this vc is only visible for new jobs.
  
      
      
      switch (gestureRecognizer.state){
      case .began:
        print("began");
        handleBeginDeleteMode();
      case .cancelled:
        print("cancelled");
      case .changed:
        print("changed");
      case .ended:
        print("ended")
      //handleEndDeleteMode();
      case .failed:
        print("falied")
      case .possible:
        print("possible)")
      }
    
    
  }
  
  func setupSliders(){
    
    if item != nil && item.getIsBox() {
      volumeRange = boxVolumeRange;
    } else {
      volumeRange = normalVolumeRange
    }
   
    setupPadsSlider()
    setupWeightAndVolumeSliders()
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
      volumeRange = boxVolumeRange;
    } else {
      volumeRange = normalVolumeRange;
    }

    setupWeightSlider();
    setupVolumeSlider();
  }
  
  
  var volumeRange : SliderRange = SliderRange(low: 1.0, high: 185.0, inc: 1.0)
  var normalVolumeRange  = SliderRange(low: 1.0, high: 185.0, inc: 1.0)
  var boxVolumeRange = SliderRange(low: 1.5, high: 42.0, inc: 0.5)
  
  func setupVolumeSlider(){
    sliderVolume.minimumValue = volumeRange.low;
    sliderVolume.maximumValue = volumeRange.high;
    
  }
  
  func isNear(value : Float , target : Float) -> Bool{
    if abs(value - target) < 0.1 {
      return true;
    }
    return false;
  }
  
  func onSliderVolumeChanged(sender: UISlider , fromUser : Bool)
  {
    
    var  cubicFeet : Float = 0.0;
    if isNear(value: volumeRange.inc, target: 1.0){
      cubicFeet = round(sender.value);
    } else {
      cubicFeet = round(sender.value * 2.0) / 2.0
    }
   
    // round to nearest inc

    item.setVolume(volume: cubicFeet);
    let styled = String(format: "%.1f", cubicFeet) + " ft3"
    // TODO superscript the 3
    let superScripted = TextUtils.formFt3Superscript(text: styled);
    if fromUser && syncWeightAndVolume == true {
      sliderWeight.value = cubicFeet * Float(poundsPerCubicFeet ) ;
      onSliderWeightChanged(sender: sliderWeight, fromUser: false)
    }
    labelVolume.attributedText = superScripted;
    
  }
  
  @IBAction func onSliderVolumeChanged(_ sender: UISlider) {
    onSliderVolumeChanged(sender: sender, fromUser: true);
  }
  
  var weightRange : SliderRange = SliderRange(low: 1.0, high: 700.0, inc: 1.0)
  var normalWeightRange  = SliderRange(low: 1.0, high: 700.0, inc: 1.0)
  var boxWeightRange = SliderRange(low: 1.0, high: 70.0, inc: 1.0)
  
  func setupWeightSlider(){
    sliderWeight.minimumValue = weightRange.low
    sliderWeight.maximumValue = weightRange.high
  }
  

  func onSliderWeightChanged(sender : UISlider, fromUser:Bool){
    let weight = round(sender.value);
    
    if syncWeightAndVolume == true && fromUser{
      sliderVolume.value = weight / Float(poundsPerCubicFeet);
      onSliderVolumeChanged(sender: sliderVolume, fromUser: false)
    }
    labelWeight.text = String(format:"%.0f", weight) + " lbs."
    item.setWeightLbs(weightLbs: weight);
    item.setMonetaryValue(value: Utility.monetaryValueFromWeight(weight: weight))

  }
  
  @IBAction func onSliderWeightChanged(_ sender: UISlider) {
    onSliderWeightChanged(sender: sender, fromUser: true)
  }

  /*
  func  weightProgressFromVolume(cubicFeet : Float) -> Int{
    let delegate = UIApplication.shared.delegate as! AppDelegate
  
    let lbsPerCubicFoot = Int((delegate.currentCompany?.poundsPerCubicFoot!)!);
    let pounds = cubicFeet * Float(lbsPerCubicFoot!);
  // how to convert to
    let progress = convertPoundsToProgress(pounds: pounds);
    return progress;
  }
  
  func convertCubicFeetToProgess( cubicFeet : Float) -> Int{
    /*for (i, next) in possibleVolumes.enumerated(){
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
 */
    return 0;
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
 */
  
  func updateInterfaceFromItem(){
    if (item.getIsBox()){
      item.setNumberOfPads(numberOfPads: 0);
      padsRow.isHidden = true;
    } else {
      padsRow.isHidden = false;
    }
    setupWeightAndVolumeSliders()
  }
  func updateFromItem(){
    
    // extract the images
    updateInterfaceFromItem();
  
    imageItems = [];
    for (key, value) in item.imageReferences!{
      let stringkey = key as! String;
      let stringValue = value as! String;
      imageItems.append(ImageItem(dateKey: stringkey, stringUri: stringValue))
    }
    
    syncWeightAndVolume = item.getSyncWeightAndVolume()
    switchSync.isOn = syncWeightAndVolume;
    
    textViewDescription.text = item.desc!
    damageDescription.text = item.damageDescription!
    buttonCategory.setTitle(item.category! + "  >", for: .normal)
    buttonPackedBy.setTitle(item.packedBy!  + "  >", for: .normal)
    
    
    sliderPads.setValue(Float(item.getNumberOfPads()), animated :true)
    sliderPads.sendActions(for: .valueChanged)
    
    sliderVolume.setValue(item.getVolume(), animated:true)
    sliderVolume.sendActions(for: .valueChanged)
    
    
    sliderWeight.setValue(item.getWeightLbs(), animated:true)
    sliderWeight.sendActions(for: .valueChanged)
    
    textViewSpecialHandling.text = item.specialHandling
    
    switchIsBox.isOn = item.getIsBox()
    switchDisassembled.isOn = item.getIsDisassembled();
    switchSync.isOn = item.getSyncWeightAndVolume()
    
    handleControlVisibility(imageItems.count)
    collectionView.reloadData()
    
    if item.desc?.characters.count == 0 && !pickLaunched{
      pickLaunched = true;
      launchMovingItemDescriptionEntryActivity(allowCancel: false)
    }
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
  
  

  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool{
    return true;
  }
  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool{
    return true;
  }
  public func textViewDidBeginEditing(_ textView: UITextView){
    activeTextView = textView;
  }
  
  public func textViewDidEndEditing(_ textView: UITextView){
    // fair enough
  }
  
  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
  {
    return true;
  }
  
  public func textViewDidChange(_ textView: UITextView){
    // fair enough
  }

  public func textViewDidChangeSelection(_ textView: UITextView)
  {
    // fair enough
  }
  

  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
  {
    return true;
  }
  
  
  func handleControlVisibility(_ imageCount : Int){
    if isLoadingFirstTime {
      photosLoadingIndicator.isHidden = false;
      labelNoPhotos.isHidden = true;
      collectionView.isHidden = true;
    } else {
      photosLoadingIndicator.isHidden = true;
      if imageCount == 0 {
        labelNoPhotos.isHidden = false;
        collectionView.isHidden = true;
      } else {
        labelNoPhotos.isHidden = true;
        collectionView.isHidden = false;
      }
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
    
    cell.deleteButton.isHidden = !deleteMode;
    if (deleteMode){
      
      
      let transformAnim  = CAKeyframeAnimation(keyPath:"transform")
      transformAnim.values  = [NSValue(caTransform3D: CATransform3DMakeRotation(0.04, 0.0, 0.0, 1.0)),NSValue(caTransform3D: CATransform3DMakeRotation(-0.04 , 0, 0, 1))]
      transformAnim.autoreverses = true
      let answer = Double(indexPath.row).truncatingRemainder(dividingBy: 2.0);
      transformAnim.duration  = (answer == 0 ) ?   0.115 : 0.105
      transformAnim.repeatCount = Float.infinity
      cell.containerView.layer.add(transformAnim, forKey: "transform")
    } else {
      cell.containerView.layer.removeAllAnimations();
    }
    
    cell.index = indexPath.row;
    cell.callback = self;
    

    
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
    
    let companyKey = delegate.userCompanyAssignment?.companyKey
    
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
    if (isBox.isOn){
      item.setNumberOfPads(numberOfPads: 0);
    }
    updateInterfaceFromItem();
    //updateFromItem();
  }
  
 func categoryToRoom(category : Category) -> String{
  switch (category){
  case .Basement:
    return Room.Basement.rawValue
    
  case .Bedroom1,
       .Bedroom2,
       .Bedroom3,
       .Bedroom4,
       .Bedroom5:
    return Room.Bedroom.rawValue
    
  case .Garage:
    return Room.Garage.rawValue
    
  case .DiningRoom:
    return Room.DiningRoom.rawValue
    
  case .Den:
    return Room.Den.rawValue
    
  case .Office:
    return Room.Office.rawValue
    
  case .LivingRoom:
    return Room.LivingRoom.rawValue
    
  case .Kitchen:
    return Room.Kitchen.rawValue
    
  case .Bathroom:
    return Room.Bathroom.rawValue
    
  case .Patio:
    return Room.Patio.rawValue
    
  case .Sunroom:
    return Room.Sunroom.rawValue
    
  case .Laundry:
    return Room.Laundry.rawValue
    
  case .Nursery:
    return Room.Nursery.rawValue
    
  case .Other:
    return Room.Other.rawValue
    
  }
  }
  
  class PickedCallback : IMovingItemPicked{
    var outer : EditItemViewController
    init(vc : EditItemViewController){
      outer = vc;
    }
    func picked(_ description: MovingItemDataDescription, category : Category) {
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      let poundsPerCubicFoot = Int((appDelegate.currentCompany?.poundsPerCubicFoot)!)
      // TODO you get the whole desc
      outer.item.desc = description.itemName
      
      outer.item.setVolume(volume: description.getCubicFeet())
      outer.item.setVolume(volume: description.getCubicFeet() * Float(poundsPerCubicFoot!));
      outer.item.setIsBox(value: description.getIsBox());
      // TODO set category
      outer.item.setCategory(category: category)
      let delegate = UIApplication.shared.delegate as! AppDelegate
      delegate.currentCategory = category;

      outer.itemRef.setValue(outer.item.asFirebaseObject())
    }
  }

  func launchMovingItemDescriptionEntryActivity(allowCancel : Bool){
    
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "MovingItemPickViewController")) as! MovingItemPickViewController;
    
    vc.category = item.getCategory()
    vc.roomString = categoryToRoom(category: item.getCategory());
    vc.allowCancel = allowCancel
    vc.callback = PickedCallback(vc: self)
    
    self.navigationController?.pushViewController(vc, animated: true);

  }

  @IBAction func pickPressed(_ sender: Any) {
    launchMovingItemDescriptionEntryActivity(allowCancel: true)
  }
  
  @IBAction func disassembledPressed(_ sender: UISwitch) {
    item.setIsDisassembled(value: sender.isOn);
  }
  
  
  func enableUserInterface(){
    switchIsBox.isEnabled = true;
    textViewDescription.isEditable = true;
    damageDescription.isEditable = true;
    pickButton.isEnabled = true;
    switchDisassembled.isEnabled = true;
    buttonCategory.isEnabled = true;
    buttonPackedBy.isEnabled = true;
    sliderPads.isEnabled = true;
    sliderVolume.isEnabled = true;
    sliderWeight.isEnabled = true;
    switchSync.isEnabled = true;
    textViewSpecialHandling.isEditable = true;
    
  }
  
  
  
  
  // called when a gesture recognizer attempts to transition out of UIGestureRecognizerStatePossible. returning NO causes it to transition to UIGestureRecognizerStateFailed
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
  {
    return true;
  }
  
  
  // called when the recognition of one of gestureRecognizer or otherGestureRecognizer would be blocked by the other
  // return YES to allow both to recognize simultaneously. the default implementation returns NO (by default no two gestures can be recognized simultaneously)
  //
  // note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES
 
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
  {
    return false;
  }
  
  
  // called once per attempt to recognize, so failure requirements can be determined lazily and may be set up between recognizers across view hierarchies
  // return YES to set up a dynamic failure requirement between gestureRecognizer and otherGestureRecognizer
  //
  // note: returning YES is guaranteed to set up the failure requirement. returning NO does not guarantee that there will not be a failure requirement as the other gesture's counterpart delegate or subclass methods may return YES
 
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool
  {
    return true;
  }
  
  //@available(iOS 7.0, *)
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool{
    return false;
  }
  
  
  // called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
  //@available(iOS 3.2, *)
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
  {
    return true;
  }
  
  
  // called before pressesBegan:withEvent: is called on the gesture recognizer for a new press. return NO to prevent the gesture recognizer from seeing this press
  //@available(iOS 9.0, *)
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool
{
  return true;
}
}


