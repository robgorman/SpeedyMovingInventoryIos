
import UIKit
import Firebase

class Address :  FirebaseDataObject {
  var street : String?
  var addressLine2 : String? // may be null
  var city : String?
  var state : String?
  var zip : String?
  
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }

  /*
  public Address(String street, String addressLine2, String city, String state, String zip){
    this.street = street;
    this.addressLine2 = addressLine2;
    this.city = city;
    this.state = state;
    this.zip = zip;
  }
 */
}
 

