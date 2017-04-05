//
//  JobsViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class JobsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource{
  
  var companyKey : String?
  var hideBackButton : Bool = false;
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var labelNoJobsMessage: UILabel!
  @IBOutlet weak var working: UIActivityIndicatorView!
  
  var user : User!
  var uca : UserCompanyAssignment?
  
  var jobRef : FIRDatabaseQuery!
  
  var jobs : [String: Job] = [:];
  var jobKeysInOrder : [String] = [];
  var dateFormatter : DateFormatter!;
  
  override func viewWillAppear(_ animated: Bool) {
    
    jobRef.observe(FIRDataEventType.value, with: {(snapshot) in
      print(snapshot.childrenCount);
      self.jobs = [:]
      let enumerator = snapshot.children;
      //if snapshot.childrenCount > 0 {
      //  self.labelNoJobsMessage.isHidden = true
      ///  self.tableView.isHidden = false;
     // } else {
      //  self.labelNoJobsMessage.isHidden = false;
      //  self.tableView.isHidden = true;
      //}
      while let next = enumerator.nextObject() as? FIRDataSnapshot{
        let job = Job(next);
        let key = next.key;
        
        // we only want to show "active" jobs and jobs appropriate to the role
        
        if self.isActive(job: job) {
          if self.canCurrentUserView(job: job, key : key){
            
            self.jobs[key] = job;

            self.jobKeysInOrder.append(key)
          }
        }
        
        //self.jobKeysInOrder.append(key);
        
        
      }
      self.checkInitialization();
      self.tableView.reloadData();
    })
    
 
  }
  
  func daysBetweenDates(startDate : Date, endDate : Date) -> Int{
    let calendar = Calendar.current
   // let components = calendar.dateComponents(<#T##components: Set<Calendar.Component>##Set<Calendar.Component>#>, from: <#T##Date#>, to: <#T##Date#>)
    let components = calendar.dateComponents([Calendar.Component.day], from: startDate, to: endDate)
    return components.day!
  }
  
  func canCurrentUserView(job: Job, key : String) -> Bool{
    let role = uca?.getRole();
    //var users = jobs.getUsers()
    if role == .AgentCrewMember || role ==  .AgentForeman || role == .CrewMember || role == .Foreman{
      
        for user in job.getUsers(){
          if user.uid == self.user.uid{
            return true;
          }
        
      }
      return false;
    }
    if role == .Customer{
      if uca?.customerJobKey != nil && uca?.customerJobKey == key{
        return true;
      } else {
        return false; 
      }
    }
    
    return true;
  }
  
  func isActive(job : Job) -> Bool {
    // a job is not active if its cancelled
    // a job is active if its lifecycle is New, LoadedForStorage or LoadedForDelivery
    // if a job is InStorage, its active if the earliest delivery date is less than 2 weeks away
    // if a job is Delivered, its active only if the signoff date was less than 14 days ago. 
    
    if job.getIsCancelled(){
      return false; 
    }
    
    let lifecycle = job.getLifecycle()
    if lifecycle == .New || lifecycle == .LoadedForStorage || lifecycle == .LoadedForDelivery{
      return true;
    } else if lifecycle == .InStorage{
      let earliestDeliveryDate = job.getDeliveryEarliestDate()
      let now = Date();
      let days = daysBetweenDates(startDate: now, endDate: earliestDeliveryDate!)
      if days < 14 {
        // this is active
        return true;
      }
      
    } else if lifecycle == .Delivered {
      if job.signatureDelivered?.getSignOffDateTime() != nil {  // this is a long ago legacy test
        
         let signOffDate = job.signatureDelivered?.getSignOffDateTime()
        let now = Date();
        let days = daysBetweenDates(startDate: signOffDate!, endDate: now)
        if days < 14{
          return true;
        }
      } else {
        return false;
      }
    }
    
    return false
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    jobRef.removeAllObservers();
 
  }
  
  var settings : UIBarButtonItem?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
     settings = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(JobsViewController.settingsPressed))
    
    self.navigationItem.rightBarButtonItem = settings
    // hide the back button only if the choose job 
    /*
    let stackSize = self.navigationController?.viewControllers.count
    self.navigationItem.hidesBackButton = true;
    if stackSize! > 1 {
      let parent = self.navigationController?.viewControllers[stackSize!-2];
      if (parent as? ChooseCompanyViewController) != nil{
       
        self.navigationItem.hidesBackButton = false;
      }
    }*/

    self.navigationItem.hidesBackButton = hideBackButton;

    

    // Do any additional setup after loading the view, typically from a nib.
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;

    user = appDelegate.currentUser;
    uca = appDelegate.userCompanyAssignment;
    
    
    let companyRef = FIRDatabase.database().reference(withPath: "/companies/" + companyKey!)
    companyRef.observeSingleEvent(of: .value, with:  {(snapshot) in
      let company = Company(snapshot)
      self.navigationItem.title = "Jobs (" + company.name! + ")";
    })
    
    jobRef = FIRDatabase.database().reference(withPath: "/joblists/" + companyKey! + "/jobs")
      .queryOrdered(byChild: "jobNumber");
    
    dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "M/d/yy";
    
    
    if !appDelegate.initializationDone {
      // set working view visible
      working.isHidden = false;
      labelNoJobsMessage.isHidden = true;
      tableView.isHidden = true;
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
        self.checkInitialization();
      })
     
    } else {
      working.isHidden = true;
      labelNoJobsMessage.isHidden = false;
      tableView.isHidden = false;
    }
    
    tableView.bounces = false;
    
    checkSchemaVersionAndWarn();
  }
 
  func checkSchemaVersionAndWarn(){
    let schemaRef = FIRDatabase.database().reference(withPath: "/schema");
  
    schemaRef.observeSingleEvent(of: FIRDataEventType.value,  with: {(snapshot) in
      
      var version : NSNumber? = nil;
      if snapshot.exists(){
         version = snapshot.value as? NSNumber
      }
      if (version != nil){
        if (version?.intValue)! > 1 {
          self.showSchemaWarning();
        }
      }
      
    });
  }
  
  func showSchemaWarning(){
    UiUtility.showAlert("Upgrade Warning", message: "The Speedy Moving Inventory Database has been upgraded. To ensure full functionality, " +
      "please upgrade to the latest version. This version has limited functionaity and may " +
      "malfunction.", presenter: self);
  }
 
  func checkInitialization() {
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
    if appDelegate.initializationDone {
      if jobs.count == 0 {
        working.isHidden = true;
        labelNoJobsMessage.isHidden = false;
        tableView.isHidden = true;
      } else {
        working.isHidden = true;
        labelNoJobsMessage.isHidden = true;
        tableView.isHidden = false;
      }
    } else {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
        self.checkInitialization();
      })
    }
  }
  
   
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // DATA Source
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    let count = jobs.count
    return count;
  }
  
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
    let cell = tableView.dequeueReusableCell(withIdentifier: "JobTableViewCell") as! JobTableViewCell
    //let row = (indexPath as NSIndexPath).row;
    //cell.labelJobNumber.text = job.jobNumber;
    //cell.labelJobName.text = job.customerFirstName! + " " + job.customerLastName!
    //cell.labelLifecycle.text = job.lifecycle
    //cell.labelPickupDate.text = "tbd"
    //cell.labelEstimatedDelivery.text = "tbd"
    
    let key = self.jobKeysInOrder[indexPath.row];
    let job = self.jobs[key]!;
    
    cell.labelJobNumber.text = job.jobNumber;
    cell.labelJobName.text = job.customerLastName! + ", " + job.customerFirstName!
    cell.labelPickupDate.text = dateFormatter.string(for: job.getPickupDateTime());
    
    cell.labelEstimatedDelivery.text = dateFormatter.string(for: job.getDeliveryEarliestDate());
    switch (job.getLifecycle()){
    case .New:
      cell.imageViewLifecycle.image = UIImage(named:"new_active");
    case .LoadedForStorage:
      cell.imageViewLifecycle.image = UIImage(named:"loaded_for_storage_active");
    case .InStorage:
      cell.imageViewLifecycle.image = UIImage(named:"in_storage_active");
    case .LoadedForDelivery:
      cell.imageViewLifecycle.image = UIImage(named:"loaded_for_delivery_active");
    case .Delivered:
      cell.imageViewLifecycle.image = UIImage(named:"delivered_active");

    }
    
    //cell.categorySwitch.addTarget(self, action: #selector(SignUpViewController.switchIsChanged(_:)), for: UIControlEvents.valueChanged)
    
    return cell;

  }
  
  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
    return 43
  }
  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?{
    let cell = tableView.dequeueReusableCell(withIdentifier: "JobsHeaderCell")
    return cell;
  }
  
  
  func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath){
    
    let key = jobKeysInOrder[indexPath.row];
    let job = self.jobs[key]!;
    print(job.customerFirstName!)
    
    
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "JobViewController")) as!JobViewController
    
    vc.jobKey = key;
    vc.companyKey = companyKey
    
    self.navigationController?.pushViewController(vc, animated: true);
    //self.present(vc!, animated: true, completion: nil);
  }
  
  func settingsPressed(){
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let logoutAction = UIAlertAction(title: "Logout", style: .default, handler: {(action) in
      self.logout();
    })
    
    let aboutAction = UIAlertAction(title: "About", style: .default, handler: {(action) in
      self.about()
    })
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in
      self.cancel()
    })
    
    
    alertController.addAction(logoutAction)
    alertController.addAction(aboutAction)
    alertController.addAction(cancelAction)
    
    let presenter = alertController.popoverPresentationController;
    presenter?.barButtonItem = settings; 
    present(alertController, animated: true, completion: nil)
    
  }
  
  func cancel(){
    // nothing to do
  }
  
  func about(){
    
    let delegate = UIApplication.shared.delegate as! AppDelegate;
    
    let user = delegate.currentUser;
    
    
    var aboutMessage = "Speedy Moving Inventory: " + Bundle.main.releaseVersionNumber!
        +  "\n" + "Build: " + Bundle.main.buildVersionNumber!
    
    if user != nil{
      let role = uca?.role
      let username = (user?.firstName)! + " " + (user?.lastName)!
      aboutMessage += "\nUser: " + username + "\nRole: " + role!
    }
    UiUtility.showAlert("About", message: aboutMessage, presenter: self)
  }
  
  func logout(){
    do{
      try FIRAuth.auth()?.signOut()
    } catch {
      print("logout failed");
    }
    
  }

  
}
