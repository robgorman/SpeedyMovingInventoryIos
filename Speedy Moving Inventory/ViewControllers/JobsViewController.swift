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
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var labelNoJobsMessage: UILabel!
  
  var user : User!
  
  var ref : FIRDatabaseQuery!
  
  var jobs : [String: Job] = [:];
  var jobKeysInOrder : [String] = [];
  
  override func viewWillAppear(_ animated: Bool) {
    
    ref.observe(FIRDataEventType.value, with: {(snapshot) in
      print(snapshot.childrenCount);
      let enumerator = snapshot.children;
      if snapshot.childrenCount > 0 {
        self.labelNoJobsMessage.isHidden = true
        self.tableView.isHidden = false;
      } else {
        self.labelNoJobsMessage.isHidden = false;
        self.tableView.isHidden = true; 
      }
      while let next = enumerator.nextObject() as? FIRDataSnapshot{
        let job = Job(next);
        let key = next.key;
        
        self.jobs[key] = job;
        self.jobKeysInOrder.append(key);
        
        
      }
      self.tableView.reloadData();
    })
    
    navigationItem.title = "Jobs"
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    ref.removeAllObservers();
 
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let settings = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(JobsViewController.settingsPressed))
    
    self.navigationItem.rightBarButtonItem = settings
    self.navigationItem.hidesBackButton = true;

    // Do any additional setup after loading the view, typically from a nib.
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;

    user = appDelegate.currentUser;
    let companyKey = user.companyKey;
    
    ref = FIRDatabase.database().reference(withPath: "/joblists/" + companyKey! + "/jobs")
      .queryOrdered(byChild: "jobNumber");
    
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
    cell.labelJobName.text = job.customerFirstName! + " " + job.customerLastName!
    cell.labelLifecycle.text = job.getLifecycle().rawValue
    cell.labelPickupDate.text = "tbd"
    cell.labelEstimatedDelivery.text = "tbd"
    
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
    
    self.navigationController?.pushViewController(vc, animated: true);
    //self.present(vc!, animated: true, completion: nil);
  }
  
  func settingsPressed(){
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let logoutAction = UIAlertAction(title: "Logout", style: .cancel, handler: {(action) in
      self.logout();
    })
    
    let aboutAction = UIAlertAction(title: "About", style: .default, handler: {(action) in
      self.about()
    })
    
    
    alertController.addAction(logoutAction)
    alertController.addAction(aboutAction)
    
    
    present(alertController, animated: true, completion: nil)
    
  }
  
  func about(){
    
    let delegate = UIApplication.shared.delegate as! AppDelegate;
    
    let user = delegate.currentUser;
    
    
    var aboutMessage = "Version: " + Bundle.main.releaseVersionNumber!
        +  "\n" + "Build: " + Bundle.main.buildVersionNumber!
    
    if user != nil{
      let role = user?.role
      let username = (user?.firstName)! + " " + (user?.lastName)!
      aboutMessage += "\nLogged in as " + username + "\nRole: " + role!
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
