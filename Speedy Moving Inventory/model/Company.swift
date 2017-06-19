import Firebase

/**
 * Created by rob on 8/11/16.
 */

class Company: FirebaseDataObject{
  var active : NSNumber?
  var address : Address?
  var contactPerson : String?
  var calT : String?
  var dateCreated : NSNumber?
  var dateDeactivated : NSNumber?
  var iccMc : String?
  // skip the jobkeys
  var logoUrl : String?
  var name : String?
  var phoneNumber : String?
  var poundsPerCubicFoot : String?
  var usDot : String?
  var website : String?
  
  var showNumberOfPadsOnItems :  NSNumber?
  var exposeValueToCustomers :  NSNumber?
  var exposeVolumeToCustomers :  NSNumber?
  
  
  var sendCustomerEmailAtJobCreation : NSNumber?
  var templateEmailAtJobCreation : String?
  
  var sendCustomerEmailAtJobPickup : NSNumber?
  var templateEmailAtJobPickup : String?
  
  var sendCustomerEmailAtJobDelivery : NSNumber?
  var templateEmailAtJobDelivery : String?
  
  var sendCustomerEmailEveryJobStatusChange : NSNumber?
  var templateEmailEveryJobStatusChange : String?
  
  var templateEmailForEmployees : String?


  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
  
  func getIsActive() -> Bool {return (active?.boolValue)!}
  
  func getExposeValueToCustomers() -> Bool {
    // default is true
    if exposeValueToCustomers == nil{
      return true;
    }
    let boolValue = exposeValueToCustomers?.boolValue
    return boolValue!
  }
  
  func getExposeVolumeToCustomers() -> Bool {
    // default is true
    if exposeVolumeToCustomers == nil{
      return true;
    }
    let boolValue = exposeVolumeToCustomers?.boolValue
    return boolValue!
  }
  
  func getShowNumberOfPadsOnItems() -> Bool {
    // default is false
    if showNumberOfPadsOnItems == nil{
      return false;
    }
    return (showNumberOfPadsOnItems?.boolValue)!
  }
  
  func getSendCustomerEmailAtJobCreation() -> Bool{
    return (sendCustomerEmailAtJobCreation?.boolValue)!
  }
  
  func getSendCustomerEmailAtJobPickup() -> Bool{
    return (sendCustomerEmailAtJobPickup?.boolValue)!
  }

  func getSendCustomerEmailAtJobDelivery() -> Bool{
    return (sendCustomerEmailAtJobDelivery?.boolValue)!
  }
  
  func getSendCustomerEmailEveryJobStatusChange() -> Bool {
    return (sendCustomerEmailEveryJobStatusChange?.boolValue)!
  }
  
  

}

