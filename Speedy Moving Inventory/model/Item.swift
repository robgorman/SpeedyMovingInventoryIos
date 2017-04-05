import Firebase
import Foundation

enum Category : String {case Basement, Bedroom1, Bedroom2, Bedroom3, Bedroom4, Bedroom5,
  Garage, DiningRoom, Den, Office, LivingRoom, Kitchen, Bathroom, Patio,
  Sunroom, Laundry, Nursery, Other

  static var allValues: [Category]{
    return [.Basement, .Bedroom1, .Bedroom2, .Bedroom3, .Bedroom4, .Bedroom5,
            .Garage, .DiningRoom, .Den, .Office, .LivingRoom, .Kitchen, .Bathroom, .Patio,
            .Sunroom, .Laundry, .Nursery, .Other];
  }
}

enum PackedBy : String {case Owner, Mover, ThirdParty

  static var allValues: [PackedBy]{
    return [.Owner, .Mover, .ThirdParty];
  }}

enum Insurance {case Released, Company, ThirdParty};

class Item : FirebaseDataObject {

  // note xxxInverse fields are just for sorting in reverse order 
  
  var category : String?
  var claimNumber : String?
  var damageDescription : String?
  var desc : String?
  var hasClaim : NSNumber?
  var hasClaimInverse : NSNumber?
  var imageReferences : NSMutableDictionary? //[String : String]? // first string is timestamp second url
  var insurance : String?
  var isBox : NSNumber?
  var isDisassembled : NSNumber?
  var isClaimActive : NSNumber?
  var claimActiveInverse : NSNumber?
  var isScanned : NSNumber?
  var isScannedInverse : NSNumber?
  var jobKey : String?
  var monetaryValue : NSNumber?
  var monetaryValueInverse: NSNumber?
  var numberOfPads: NSNumber?
  var numberOfPadsInverse: NSNumber?
  var packedBy : String?
  var specialHandling : String?
  var uidOfCreator : String?
  var volume: NSNumber?
  var volumeInverse: NSNumber?
  var weightLbs: NSNumber?
  var weightLbsInverse: NSNumber?
  var syncWeightAndVolume : NSNumber?
  var itemWasCreatedOutOfPhase : NSNumber?
  // latest adds may be nil?
  var createDateTime : NSNumber?
  var createDateTimeInverse : NSNumber?
  
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
    // transform null images references to empty collection
    if imageReferences == nil{
      imageReferences = NSMutableDictionary()
    }
  }
  
  init(
    category: Category,
    numberOfPads : Int,
    uidOfCreator : String,
    desc : String,
    monetaryValue : Int,
    weightLbs : Float,
    volume : Float,
    specialHandling : String,
    jobKey : String,
    packedBy : PackedBy,
    isBox : Bool,
    itemWasCreatedOutOfPhase : Bool,
    createDateTime : Date)
  {
    
    super.init()
    self.setCategory(category: category)
    self.setNumberOfPads(numberOfPads: numberOfPads)
    self.uidOfCreator = uidOfCreator
    self.desc = desc
    self.setMonetaryValue(value: monetaryValue)
    self.setWeightLbs(weightLbs: weightLbs)
    self.setVolume(volume: volume)
    self.specialHandling = specialHandling
    self.jobKey = jobKey
    self.setPackedBy(packedBy: packedBy)
    self.imageReferences = NSMutableDictionary()
    self.claimNumber = ""
    self.setHasClaim(value: false)
    self.setIsClaimActive(value: false)
    self.insurance = "None"
    self.setIsScanned(value: false)
    self.damageDescription = ""
    self.setIsBox(value: isBox)
    self.setSyncWeightAndVolume(value: true)
    self.setIsDisassembled(value : false)
    self.setItemWasCreatedOutOfPhase(value : itemWasCreatedOutOfPhase)
    self.setCreateDateTime(value: createDateTime)

  }
  
  func asFirebaseObject() -> [String : Any] {
    var fbo = [String:Any]()
    fbo["category"] = category
    fbo["claimNumber"] = claimNumber
    fbo["damageDescription"] = damageDescription
    fbo["description"] = desc
    fbo["hasClaim"] = hasClaim
    fbo["hasClaimInverse"] = hasClaimInverse
    fbo["imageReferences"] = imageReferences
    fbo["insurance"] = insurance
    fbo["isBox"] = isBox
    fbo["isClaimActive"] = isClaimActive
    fbo["claimActiveInverse"] = claimActiveInverse
    fbo["isScanned"] = isScanned
    fbo["isScannedInverse"] = isScannedInverse
    fbo["jobKey"] = jobKey
    fbo["monetaryValue"] = monetaryValue
    fbo["monetaryValueInverse"] = monetaryValueInverse
    fbo["numberOfPads"] = numberOfPads
    fbo["numberOfPadsInverse"] = numberOfPadsInverse
    fbo["packedBy"] = packedBy
    fbo["specialHandling"] = specialHandling
    fbo["uidOfCreator"] = uidOfCreator
    fbo["volume"] = volume
    fbo["volumeInverse"] = volumeInverse
    fbo["weightLbs"] = weightLbs
    fbo["weightLbsInverse"] = weightLbsInverse
    fbo["syncWeightAndVolume"] = syncWeightAndVolume
    fbo["isDisassembled"]=isDisassembled
    fbo["itemWasCreatedOutOfPhase"] = itemWasCreatedOutOfPhase
    fbo["createDateTime"] = createDateTime
    fbo["createDateTimeInverse"] = createDateTimeInverse
    
    return fbo; 

  }
  
  func getHasClaim() -> Bool {return (hasClaim?.boolValue)!}
  func getHasClaimInverse() -> Bool {return ((hasClaimInverse?.boolValue)!)}
  func getIsBox() -> Bool {return ((isBox?.boolValue)!)}
  func getIsClaimActive() -> Bool {return ((isClaimActive?.boolValue)!)}
  func getClaimActiveInverse() -> Bool {return ((claimActiveInverse?.boolValue)!)}
  func getIsScanned() -> Bool {return ((isScanned?.boolValue)!)}
  func getIsScannedInverse() -> Bool {return ((isScannedInverse?.boolValue)!)}
  func getMonetaryValue() -> Int {return ((monetaryValue?.intValue)!)}
  func getMonetaryValueInverse() -> Int {return ((monetaryValueInverse?.intValue)!)}
  func getNumberOfPads() -> Int {return ((numberOfPads?.intValue)!)}
  func getNumberOfPadsInverse() -> Int {return ((numberOfPadsInverse?.intValue)!)}
  func getVolume() -> Float {return ((volume?.floatValue)!)}
  func getVolumeInverse() -> Float {return ((volumeInverse?.floatValue)!)}
  func getWeightLbs() -> Float {return ((weightLbs?.floatValue)!)}
  func getWeightLbsInverse() -> Float {return ((weightLbsInverse?.floatValue)!)}
  func getSyncWeightAndVolume() -> Bool {
    // handle null just because it is occurring
    if syncWeightAndVolume == nil{
      return true
    }
    return (syncWeightAndVolume?.boolValue)!
  }
  
  func getIsDisassembled() -> Bool {
    if (isDisassembled == nil){
      isDisassembled = NSNumber(value : false);
    }
    return (isDisassembled?.boolValue)!
  }
  
  func getItemWasCreatedOutOfPhase() -> Bool{
    if (itemWasCreatedOutOfPhase == nil){
      itemWasCreatedOutOfPhase = NSNumber(value : false)
    }
    return (itemWasCreatedOutOfPhase?.boolValue)!;
  }
  
  func getCreateDateTime() -> Date {
    if createDateTime == nil {
      return Date();
    }
    return Utility.convertNsNumberToDate(rawValue: createDateTime)
  }

  func setNumberOfPads(numberOfPads : Int){
    self.numberOfPads = NSNumber(value: numberOfPads)
    self.numberOfPadsInverse = NSNumber(value: -numberOfPads);
  }
  
  func setWeightLbs(weightLbs : Float){
    self.weightLbs = NSNumber(value: weightLbs)
    self.weightLbsInverse = NSNumber(value: -weightLbs);
  }
  
  func setMonetaryValue(value : Int){
    self.monetaryValue = NSNumber(value: value)
    self.monetaryValueInverse = NSNumber(value :  -value);
  }
  
  func setCreateDateTime(value : Date){
    let convertedDate = Utility.convertDateToNsNumber(date: value)
    self.createDateTime = convertedDate;
    self.createDateTimeInverse = NSNumber(value : convertedDate.int64Value * -1);
  }
  
  
  func setVolume(volume : Float){
    self.volume = NSNumber(value: volume)
    self.volumeInverse = NSNumber(value: -volume);
  }
  
  func setIsClaimActive(value : Bool){
    self.isClaimActive = NSNumber(value : value)
    self.claimActiveInverse = NSNumber(value : !value)
  }
  
  func setHasClaim(value : Bool){
    self.hasClaim = NSNumber(value : value)
    self.hasClaimInverse = NSNumber(value : !value)
  }
  
  func setIsScanned(value : Bool){
    self.isScanned = NSNumber(value : value)
    self.isScannedInverse = NSNumber(value : !value)
  }
  
  func getCategory() -> Category{
    let cat = Category(rawValue: self.category!);
    return cat!
  }
  
  func setCategory(category : Category){
    self.category = category.rawValue;
  }
  
  func getPackedBy() -> PackedBy{
    let packedBy = PackedBy(rawValue: self.packedBy!);
    return packedBy!
  }
  
  func setPackedBy(packedBy : PackedBy){
    self.packedBy = packedBy.rawValue;
  }
  
  func setIsBox(value : Bool){
    self.isBox = NSNumber(value: value)
  }
  
  func setIsDisassembled(value : Bool){
    self.isDisassembled = NSNumber(value: value)
  }
  
  func setSyncWeightAndVolume(value : Bool){
    self.syncWeightAndVolume = NSNumber(value: value)
  }
  
  func setItemWasCreatedOutOfPhase(value : Bool){
    self.itemWasCreatedOutOfPhase = NSNumber(value : value)
   
  }
}
