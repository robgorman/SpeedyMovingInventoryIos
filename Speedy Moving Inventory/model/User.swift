import UIKit
import Firebase


enum Role : String { case CompanyAdmin, Foreman, AgentForeman, CrewMember, AgentCrewMember, Customer}

class User : FirebaseDataObject {


  static var roleLabels = [ "Company Admin", "Foreman", "Agent Foreman", "Crew Member", "Agent Crew Member", "Customer"];

  var firstName : String?
  var lastName : String?
  var uid : String?
  var emailAddress : String?
  

  required init(_ snapshot: FIRDataSnapshot){
    super.init(snapshot);
  }
  
  
  

  
 }
