//
//  SignOffEmailSender.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 5/15/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

protocol SenderListener {
  // protocol definition goes here
  func sendSuccess()
  
  func sendFailure(message : String)

}

class SignOffEmailSender: NSObject {
  
  
  var company : Company
  var jobKey :  String
  
  var recipientList : String
  var mailServer  :  Server

  var companyKey : String
  var job : Job?
  
  var listener : SenderListener?
  var presenter : UIViewController
  
  public init( presenter : UIViewController,
               mailServer : Server ,
             
               recipientList : String, company : Company,
               companyKey : String, jobKey : String) {
    
    self.company = company;
    self.jobKey = jobKey;
    self.recipientList = recipientList;
    self.mailServer = mailServer;
    self.companyKey = companyKey;
    self.presenter = presenter
  }
  
  func send(listener : SenderListener){
    self.listener = listener;
    sendSignOffEmails()
  }
  
  fileprivate func sendSignOffEmails(){
    let jobRef = FIRDatabase.database().reference(withPath:"/joblists/" + companyKey + "/jobs/" + jobKey)
    jobRef.observeSingleEvent(of: .value, with: {(snapshot) in
      self.job = Job(snapshot)
      self.sendUserEmail()
      self.sendCompanyEmail()
    })
  }
  
  fileprivate func formSingleLineCompanyAddress(company : Company) -> String {
    let addressLine1 = company.address?.street
    var addressLine2 = ""
    var addressLine3 = ""
    
    if (company.address?.addressLine2?.characters.count)! > 1{
      addressLine2 = (company.address?.addressLine2)!
      addressLine3 = (company.address?.city)! + ", "
    } else {
      let t1 =  (company.address?.city)! + ", "
      let t2 = (company.address?.state)! + " " + (company.address?.zip!)!
      addressLine2 =  t1 + t2
      addressLine3 = ""
    }
    var address = addressLine1! + ", " + addressLine2
    if (addressLine3.characters.count > 0) {
      address = address + ", " + addressLine3
    }
    return address
  }
  
  fileprivate func formMultiLineCompanyAddress(company : Company) -> String {
    let addressLine1 = company.address?.street
    var addressLine2 = ""
    var addressLine3 = ""
    
    if (company.address?.addressLine2?.characters.count)! > 1{
      addressLine2 = (company.address?.addressLine2)!
      let city = (company.address?.city!)! + ", "
      let state = (company.address?.state)! + " "
      let zip = company.address?.zip
      addressLine3 = city + state + zip!
    } else {
      let city = (company.address?.city!)! + ", "
      let state = (company.address?.state)! + " "
      let zip = company.address?.zip
      addressLine2 =  city + state + zip!
      addressLine3 = ""
    }
    var address = addressLine1! + "\n" + addressLine2
    if (addressLine3.characters.count > 0) {
      address = address + "\n" + addressLine3
    }
    return address
  }

  fileprivate func substitute(template : String) -> String{
    var substitution = template;
    let customerName = (job?.customerFirstName!)! + " " + (job?.customerLastName!)!;
    
    substitution = substitution.replacingOccurrences(of: "<<CustomerName>>",
                                             with: customerName,
                                             options: NSString.CompareOptions.caseInsensitive)
    substitution = substitution.replacingOccurrences(of: "<<CompanyName>>",
                                                 with: company.name!,
                                                 options: NSString.CompareOptions.caseInsensitive)
    substitution = substitution.replacingOccurrences(of: "<<CompanyMultiLineAddress>>",
                                                 with: formMultiLineCompanyAddress(company: company),
                                                 options: NSString.CompareOptions.caseInsensitive)
    substitution = substitution.replacingOccurrences(of: "<<CompanySingleLineAddress>>",
                                                 with: formSingleLineCompanyAddress(company: company),
                                                 options: NSString.CompareOptions.caseInsensitive)
    
    substitution = substitution.replacingOccurrences(of: "<<CompanyPhone>>",
                                                 with: PhoneNumberFormatter.format(company.phoneNumber!),
                                                 options: NSString.CompareOptions.caseInsensitive)

    substitution = substitution.replacingOccurrences(of: "<<CompanyWebSite>>",
                                                 with: company.website!,
                                                 options: NSString.CompareOptions.caseInsensitive)

    let appDelegate = UIApplication.shared.delegate as! AppDelegate;
    let firebaseHost = appDelegate.webAppUrl
    let customerNameString = (job?.customerFirstName!)! + " " + (job?.customerLastName!)!
    var signupUrl = firebaseHost! + "/user-sign-up"
    signupUrl += "?companyname=" + (company.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))!
    signupUrl += "&customeremail=" + (job?.customerEmail?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)!
    signupUrl += "&logurl=" + (company.logoUrl?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)!
    signupUrl += "&customername=" + customerNameString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    signupUrl += "&isCustomer=" + (company.name?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))!
    signupUrl = "<a href=\"" + signupUrl + "\">Sign Up</a>";
    
    substitution = substitution.replacingOccurrences(of: "<<CustomerPortalSignupLink>>",
                                                 with: signupUrl,
                                                 options: NSString.CompareOptions.caseInsensitive)
    
    var portalUrl = firebaseHost!;
    portalUrl = "<a href=\"" + portalUrl + "\">Portal</a>";
    substitution = substitution.replacingOccurrences(of: "<<PortalLink>>",
                                                 with: portalUrl,
                                                 options: NSString.CompareOptions.caseInsensitive)

    let pickupDateFormatter = DateFormatter()
    pickupDateFormatter.dateFormat = "M/d/yy h:mm z"
    let pDateTime = job?.getPickupDateTime()
    let dateString = pickupDateFormatter.string(from : pDateTime!)
    substitution = substitution.replacingOccurrences(of: "<<MovePickupDateTime>>",
                                                 with: dateString,
                                                 options: NSString.CompareOptions.caseInsensitive)

    let companyLogo = "<img src=\"" + company.logoUrl! + "\">";
    substitution = substitution.replacingOccurrences(of: "<<CompanyLogo>>",
                                                 with: companyLogo,
                                                 options: NSString.CompareOptions.caseInsensitive)
    substitution = substitution.replacingOccurrences(of: "<<JobStatus>>",
                                                 with: (job?.lifecycle!)!,
                                                 options: NSString.CompareOptions.caseInsensitive)

    substitution = substitution.replacingOccurrences(of: "<<JobNumber>>",
                                                 with: (job?.jobNumber!)!,
                                                 options: NSString.CompareOptions.caseInsensitive)

    substitution = substitution.replacingOccurrences(of: "\n", with: "<br>")
    
    
    return substitution
  }
  
  fileprivate func sendCompanyEmail(){
    let messageBody = substitute(template: company.templateEmailForEmployees!)
    let subject = "Job Number: " + (job?.jobNumber!)!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate;

    let mailServer = appDelegate.mailServer!
    
    mailServer.sendEmailMessage(recipients: recipientList, subject: subject,
                                messageBody: messageBody,
                                fromEmailAddress: "noreply@speedymovinginventory.com",
     success: { (message) in
        //UiUtility.showAlert("Emails Sent", message: "Signoff emails successfully sent.", presenter: presenter)
      print("success: " + message);
      
     },
     failure: {(message) in
      // UiUtility.showAlert("Email Failure", message: "Signoff successful but emails not sent." + message, presenter: presenter)
      print("failure: " + message)
    })
    
  }
  
  fileprivate func sendUserEmail(){
    var messageBody = "";
    var subject = "";
    let lifecycle : Lifecycle = job!.getLifecycle()
    switch lifecycle {
    case .New:
      // this case should't occur
    break;
    case .LoadedForStorage:
      if company.getSendCustomerEmailAtJobPickup(){
        messageBody = substitute(template: company.templateEmailAtJobPickup!)
        subject = "Job Pickup Complete"
      }
    case .InStorage, .LoadedForDelivery:
      if company.getSendCustomerEmailEveryJobStatusChange(){
        messageBody = substitute(template: company.templateEmailAtJobPickup!)
        subject = "Job Status: " + (job?.lifecycle!)!
      }
   
    case .Delivered:
      if company.getSendCustomerEmailAtJobDelivery(){
        messageBody = substitute(template: company.templateEmailAtJobDelivery!)
        subject = "Job Delivery Complete"
      }

    }
    
    if messageBody.characters.count > 0{
      mailServer.sendEmailMessage(recipients: (job?.customerEmail!)!,
                                  subject: subject,
                                  messageBody: messageBody,
                                  fromEmailAddress: "noreply@speedymovinginventory.com",
      success: { (message) in
       
        DispatchQueue.main.async  {
          print("success: " + message);
          self.listener?.sendSuccess()
        }

      },
      failure:  {(message) in
        print("failure : " + message)
        self.listener?.sendFailure(message: message)
      })
    }
  }
}
