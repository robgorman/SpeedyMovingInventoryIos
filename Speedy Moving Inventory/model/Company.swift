import Firebase

/**
 * Created by rob on 8/11/16.
 */

class Company: FirebaseDataObject{
  var active : Bool?
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
  
  var users : [String]? // first string is timestamp second url

  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }

}

