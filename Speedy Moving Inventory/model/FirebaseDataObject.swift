//
//  FirebaseDataObject.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

//
//  FIRDataObject.swift
//
//  Created by Callam Poynter on 24/06/2016.
//

import Firebase

open class FirebaseDataObject: NSObject {
  
  let snapshot: FIRDataSnapshot
  var key: String { return snapshot.key }
  var ref: FIRDatabaseReference { return snapshot.ref }
  
  
  public override init(){
    self.snapshot = FIRDataSnapshot()
    super.init()
  
  }
  
 
  required public init(_ snapshot: FIRDataSnapshot) {
    
    self.snapshot = snapshot
    
    super.init()
    
    for child in snapshot.children.allObjects as? [FIRDataSnapshot] ?? [] {
      // we have to map "description" to "desc" because NSObjectProtocol has description
      var key = child.key
      if (key == "description"){
        key = "desc"
      }
      
      if (key == "originAddress"){
        setValue(Address(child), forKey: key)
      } else if (key == "destinationAddress"){
        setValue(Address(child), forKey: key)
      } else if (key == "address"){
        setValue(Address(child), forKey : key)
      } else if (key == "signatureLoadedForStorage" || key == "signatureInStorage"
        || key == "signatureLoadedForDelivery" || key == "signatureDelivered"){
        setValue(Signature(child), forKey : key)
      } else if (key == "users" ){
        // 
        if self is Job {
          print("what to do")
          var users : [UserIdMapEntry] = [];
          let all = child.value as! NSDictionary;
        
          for key in all.allKeys {
            let id = key as! String
            let nextMap = UserIdMapEntry(uid: id);
         
            users.append(nextMap);
          }
          setValue(users, forKey:key);
        } else if self is Company {
          print("we can ignore for now");
        }
      } else if (key == "signatureNew"){
        // just ignore
        print("ignore")
      } else if responds(to: Selector(key)) {
        setValue(child.value, forKey:key)
      }
    }
  }
}
protocol FirebaseDatabaseReferenceable {
  var ref: FIRDatabaseReference { get }
}

extension FirebaseDatabaseReferenceable {
  var ref: FIRDatabaseReference {
    return FIRDatabase.database().reference()
  }
}
