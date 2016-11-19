import UIKit
import Firebase


enum Role : String { case ServiceAdmin, CompanyAdmin, Foreman, AgentForeman, CrewMember, AgentCrewMember, Customer}

class User : FirebaseDataObject {


  static var roleLabels = ["Service Admin", "Company Admin", "Foreman", "Agent Foreman", "Crew Member", "Agent Crew Member", "Customer"];


  var companyKey : String?
  var firstName : String?
  var isDisabled : NSNumber?
  var lastName : String?
  var role : String?
  var uid : String?
  var emailAddress : String?

  /*
  init(companyKey : String, firstName : String, lastName : String, role : String, uid : String,
                                       emailAddress : String){
    self.companyKey = companyKey;
    self.firstName = firstName;
    self.lastName = lastName;
    self.role = role;
    self.uid = uid;
    self.isDisabled = false;

    self.emailAddress = emailAddress;
  }
 */
  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
 
  func getRole() -> Role{
    let role = Role(rawValue: self.role!);
    return role!
  }
  

  
 }
