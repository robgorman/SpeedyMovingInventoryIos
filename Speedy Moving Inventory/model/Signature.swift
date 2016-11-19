import Firebase

class Signature : FirebaseDataObject {
  var name : String?
  var imageUrl : String?

  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
 
}
