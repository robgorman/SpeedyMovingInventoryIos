
/**
 * Created by rob on 9/18/16.
 */
/*
public class UserIdMapEntry extends Model {
  private String uid;
  private Boolean alwaysTrue;

  public UserIdMapEntry(){

  }

  public String getUid() {
    return uid;
  }

  public Boolean getAlwaysTrue() {
    return alwaysTrue;
  }
}
*/
import Foundation
import UIKit
import Firebase

class UserIdMapEntry : FirebaseDataObject {
  
  // note xxxInverse fields are just for sorting in reverse order
  
  var uid : String?
  var alwaysTrue : NSNumber?

  required init(_ snapshot : FIRDataSnapshot){
    super.init(snapshot);
  }
  
  init(uid : String){
    super.init();
    self.uid = uid;
    alwaysTrue = true; 
  }
  
}
