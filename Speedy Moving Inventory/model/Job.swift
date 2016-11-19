import UIKit
import Firebase



enum Lifecycle : String   {case New, LoadedForStorage, InStorage, LoadedForDelivery, Delivered
  static var allValues: [Lifecycle]{
    return [.New, .LoadedForStorage, .InStorage, .LoadedForDelivery, .Delivered];
  }}

 open class Job : FirebaseDataObject {

  var companyKey : String?
  var createDateTime : NSNumber?
  var customerEmail : String?
  var customerFirstName : String?
  var customerLastName : String?
  var customerPhone : String?
  var deliveryEarliestDate : NSNumber?
  var deliveryLatestDate : NSNumber?
  var destinationAddress : Address?
  var jobNumber : String?
  var lifecycle : String?
  var originAddress : Address?
  var pickupDateTime : NSNumber?
  var signatureDelivered : Signature? // can be null
  var signatureInStorage : Signature? // can be null
  var signatureLoadedForDelivery : Signature? // can be null
  var signatureLoadedForStorage : Signature? // can be null
  var signatureNew : Signature? // can be null
  var storageInTransit : NSNumber?
  // TODO we have to add this back
  //var Map<String, UserIdMapEntry> users; // can be null

  required public init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }

  func getLifecycle() -> Lifecycle{
    let lifecycle = Lifecycle(rawValue: self.lifecycle!);
    return lifecycle!
  }
  
  func setLifecycle(lifecycle : Lifecycle){
    self.lifecycle = lifecycle.rawValue;
  }
  

  
  
  func getPickupDateTime() -> Date{
    return Utility.convertNsNumberToDate(rawValue: pickupDateTime)
  }
  
  func getDeliveryEarliestDate() -> Date?{
    if deliveryEarliestDate != nil{
      return Utility.convertNsNumberToDate(rawValue: deliveryEarliestDate)
    }
    return nil;
  }
  
  func getDeliveryLatestDate() -> Date?{
    if deliveryLatestDate != nil{
      return Utility.convertNsNumberToDate(rawValue: deliveryLatestDate)
    }
    return nil;
  }

  func getStorageInTransit() -> Bool{
    return (storageInTransit?.boolValue)!
  }
}
