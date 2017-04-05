import Firebase

class Signature : FirebaseDataObject {
  var name : String?
  var imageUrl : String?
  var signOffDateTime : NSNumber?

  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
  
  init( name : String, imageUrl : String, signOffDateTime : Date){
    super.init()
    self.name = name;
    self.imageUrl = imageUrl;
    self.signOffDateTime = Utility.convertDateToNsNumber(date: signOffDateTime);
  }
 
  func getSignOffDateTime() -> Date {
    if signOffDateTime == nil{
      signOffDateTime = Date().timeIntervalSince1970 as NSNumber?;
    }
    
     return Utility.convertNsNumberToDate(rawValue: signOffDateTime)
  }
  
  
  func asFirebaseObject() -> [String : Any] {
    var fbo = [String:Any]()
    fbo["name"] = name
    fbo["imageUrl"] = imageUrl
    fbo["signOffDateTime"] = signOffDateTime

    
     
    return fbo;
    
  }

}
