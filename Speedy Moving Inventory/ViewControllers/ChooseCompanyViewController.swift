//
//  ChooseCompanyViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 1/2/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Foundation
import UIKit
import Firebase

class CompanyAndUca{
  var company : Company
  var uca     : UserCompanyAssignment
  init(company : Company, uca : UserCompanyAssignment){
    self.company = company;
    self.uca = uca;
  }
}

class ChooseCompanyViewController : UIViewController, UITableViewDelegate, UITableViewDataSource{
  
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var messageView: UIView!
 
  @IBOutlet weak var working: UIActivityIndicatorView!
  
  var user : User!
  
  
  var companies : [CompanyAndUca] = []
  var assignments : [UserCompanyAssignment] = [];
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.hidesBackButton = true;
    
    // Do any additional setup after loading the view, typically from a nib.
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
    
    user = appDelegate.currentUser;
    
    let ref = FIRDatabase.database().reference(withPath: "/companyUserAssignments/")
    .queryOrdered(byChild: "uid")
    .queryStarting(atValue: user.uid)
      .queryEnding(atValue: user.uid)
    
    ref.observe(FIRDataEventType.childAdded, with: {(snapshot) in
      let uca = UserCompanyAssignment(snapshot)
      if !uca.getIsDisabled() {
        self.assignments.append(uca);
      }
    });
    
    ref.observeSingleEvent(of: .value, with: {(snaphot) in
      print("done");
      let appDelegate = UIApplication.shared.delegate as! AppDelegate;
      ref.removeAllObservers();
      if self.assignments.count == 0{
        // error
        UiUtility.showAlert("Error", message: "There are no company assignments for this user. Contact support.", presenter: self);
        //self.logout();
      } else if (self.assignments.count == 1){
        // launch jobsVC
        let uca = self.assignments[0];
        if uca.getRole() == Role.Customer {
          UiUtility.showAlertWithDismissAction("Customer Login Not Supported", message: "We apologize, but our mobile app does not support customer logins at this time. Please try the web interface at https://app.speedymovinginventory.com", presenter: self,
          dismiss:{_ in
            do{
              try FIRAuth.auth()?.signOut()
            } catch {
              print("logout failed");
            }
            appDelegate.resetCredentials();
            exit(0);
          });
         
          return
        }
          
        
        appDelegate.userCompanyAssignment = self.assignments[0];
        let companyKey = appDelegate.userCompanyAssignment?.companyKey;
        // TODO set appdelegate current co
        let companyRef = FIRDatabase.database().reference(withPath: "/companies/" + companyKey!);
        companyRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
          let company = Company(snapshot)
          
          appDelegate.currentCompany = company;
          let vc = (self.storyboard?.instantiateViewController(withIdentifier: "JobsViewController")) as! JobsViewController
          vc.hideBackButton = true
          vc.companyKey = self.assignments[0].companyKey;
          //self.navigationController?.popViewController(animated: false)
          self.navigationItem.hidesBackButton = true;
          self.navigationController?.pushViewController(vc, animated: true);
          
        })

        
      } else {
        for uca in self.assignments {
          let companyRef = FIRDatabase.database().reference(withPath: "/companies/" + uca.companyKey!);
          companyRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
            let company = Company(snapshot)
            let companyAndUca = CompanyAndUca(company: company, uca: uca)
            self.companies.append(companyAndUca)
            self.tableView.reloadData()
            self.updateUiFromData()
          })

        }
      }
    });
    
    
    tableView.bounces = false;
    
  }
  
  func updateUiFromData(){
    if companies.count > 0 {
      tableView.isHidden = false;
      messageView.isHidden = false;
      working.isHidden = true;
    }
  }
  
  func logout(){
    do{
      try FIRAuth.auth()?.signOut()
    } catch {
      print("logout failed");
    }
    
  }


  override func viewWillAppear(_ animated: Bool) {
    
      navigationItem.title = "Choose A Mover"
  }
  
  
  override func viewWillDisappear(_ animated: Bool) {
  
    
  }
  
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // DATA Source
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    let count = companies.count
    return count;
  }
  
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseCompanyTableViewCell") as! ChooseCompanyTableViewCell
     
    let company = companies[indexPath.row].company;
    cell.name.text = company.name
    cell.phone.text = PhoneNumberFormatter.format(company.phoneNumber!)
    if (company.contactPerson == nil || company.contactPerson?.characters.count == 0){
      cell.contact.text = "None"
    } else {
      cell.contact.text = company.contactPerson;
    }
    
    
    return cell;
    
  }
  
  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
    return 43
  }
  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?{
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseCompanyHeaderCell")
    return cell;
  }
  
  
  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath){
    
    let companyAndUca = companies[indexPath.row];
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "JobsViewController")) as! JobsViewController
    vc.hideBackButton = false;
    vc.companyKey = companyAndUca.uca.companyKey;
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
    appDelegate.userCompanyAssignment = companyAndUca.uca;
    
    let companyRef = FIRDatabase.database().reference(withPath: "/companies/" + companyAndUca.uca.companyKey!);
    companyRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
      let company = Company(snapshot)
    

    
      appDelegate.currentCompany = company;
      let back = UIBarButtonItem()
      back.title = " ";
      self.navigationItem.backBarButtonItem = back;
      self.navigationController?.pushViewController(vc, animated: true);

    });
    
       //self.present(vc!, animated: true, completion: nil);
  }
  
  
  
}
