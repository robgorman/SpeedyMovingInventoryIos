//
//  Server.swift
//  MyBusinessCard
//
//  Created by rob gorman on 3/6/16.
//  Copyright © 2016 Rancho Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public class Server : NSObject{
  
  
  var serverUrl : String?;
  
  init(baseUrl : String){
    super.init()
    serverUrl = baseUrl;
  }
  
  func sendEmailMessage(
    recipients : String,
    subject : String,
    messageBody : String,
    fromEmailAddress : String,
    success : @escaping (String)->Void,
    failure : @escaping (String)->Void)
  {
    request(serverUrl! + "/sendemail", method:HTTPMethod.get,
            parameters: ["recipients" : recipients,
                         "subject" : subject,
                         "body" : messageBody,
                         "fromemailaddress" : fromEmailAddress])
    .validate()
      .responseJSON {response in
        switch response.result {
        case .success:
          if let value = response.result.value{
            let response = ServletResponse(json: JSON(value))
            if response.success{
              success(response.errorMessage)
            } else {
              failure(response.errorMessage)
            }
          }
        case .failure (let error):
          failure(error.localizedDescription)
        }
    }
    
  }
    
  
 
  func sendNewSignoffEmailMessage(
    recipients: String,
    companyName : String,
    linkUrl : String,
    customerName : String,
    lifecycle : String,
    jobNumber : String,
    companyPhone : String,
    success : @escaping (String)->Void,
    failure : @escaping (String)->Void){
    request(serverUrl! + "/sendsignoffemail", method: HTTPMethod.get,
            parameters: ["recipients" : recipients,
                         "companyname" : companyName,
                         "linkurl" : linkUrl,
                         "customername" : customerName,
                         "lifecycle" : lifecycle,
                         "jobnumber" : jobNumber,
                         "companyphone" :  companyPhone])
      .validate()
      .responseJSON {response in
        switch response.result {
        case .success:
          if let value = response.result.value{
            let response = ServletResponse(json: JSON(value))
            if response.success{
              success(response.errorMessage)
            } else {
              failure(response.errorMessage);
            }
          }
        case .failure (let error):
          failure(error.localizedDescription)
          
        }
    }
  }
  


}
