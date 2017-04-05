
//  JobsViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase


class ForgotPasswordViewController : UIViewController, UITextFieldDelegate, UITextViewDelegate{
  
  var companyKey : String?
  
  var activeTextField: UITextField?;
  
  @IBOutlet weak var feedbackMessageLabel: UILabel!
  @IBOutlet weak var emailEditText: UITextField!
  @IBOutlet weak var sendResetInstructionsButton: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "Forgot Password"

    feedbackMessageLabel.isHidden = true;
    // Do any additional setup after loading the view, typically from a nib.
    ButtonStyler.style(sendResetInstructionsButton)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
     }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func attemptToSend(){
    self.feedbackMessageLabel.isHidden = true
    let email = emailEditText.text;
    var cancel = false;
    
    if TextUtils.isEmpty(email!){
      UiUtility.showAlert("Error", message: "This field is required", presenter: self)
      cancel = true;
    } else if !TextUtils.isValidEmail(email: email!){
      UiUtility.showAlert("Invalid Address", message: "The email address is invalid", presenter: self)
      cancel = true;
    }
    
    if cancel{
      return;
    }
    
    sendResetInstructions(email: email!)
  }
  
  func sendResetInstructions(email : String){
    Hud.on(self)
    FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: {error in
      if error != nil{
        self.feedbackMessageLabel.text = "Reset request failed: " + (error?.localizedDescription)!;
        
      } else {
        self.feedbackMessageLabel.text = "Reset succeeded! Check " + email + " for instuctions."
      }
      self.feedbackMessageLabel.isHidden = false;
      Hud.off(self)
    })
  }
  @IBAction func sendResetInstructionsPressed(_ sender: AnyObject) {
    attemptToSend()
  }
  
  /// text field delegate
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool // return NO to disallow editing.
  {
    
    return true;
  }
  func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
  {
   
    activeTextField = textField;
  }
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
  {
    return true;
  }
  
  
  
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
  {
    textField.resignFirstResponder()
    return true;
  }

 
}
