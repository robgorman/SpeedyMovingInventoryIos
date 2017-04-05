//
//  LoginViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class LoginViewController :  UIViewController, UITextFieldDelegate, UITextViewDelegate, FirebaseDatabaseReferenceable{
  
  // input vaar
  var allowAutoLogin = true;
  
  @IBOutlet weak var editEmail: UITextField!
  @IBOutlet weak var editPassword: UITextField!

  @IBOutlet weak var buttonSignIn: UIButton!
  @IBOutlet weak var buttonForgotPassword: UIButton!
  
   @IBOutlet weak var checkRememberMe: UISwitch!
  @IBOutlet weak var workingView: UIView!
  
  @IBOutlet weak var loginForm: UIView!
 
  var activeTextField: UITextField?;

  
  var auth : FIRAuth? = nil;
  
  var navigationBarHiddenState : Bool! = false;
 
  var fired = false;
  var listenerHandle : FIRAuthStateDidChangeListenerHandle!;
  
  var isLoggingIn : Bool = false;
  
  var usersReference : FIRDatabaseReference?
  
  override func viewWillAppear(_ animated: Bool) {
    navigationBarHiddenState = self.navigationController?.isNavigationBarHidden
    self.navigationController?.isNavigationBarHidden = true; 
    // TODO add the auth state listener. My current issue is that
    // I can't figure out how to save the listener in a block
    fired = false;
    //showProgressView(progress: true);

    listenerHandle = auth?.addStateDidChangeListener({
      auth, user in
      
      if self.fired{
        return
      }
        
      if user != nil{
        self.fired = true;
        self.lookupDatabaseUser(user!)
        
      }
      }
    );
    
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
    let credentials = appDelegate.getSavedCredentials()
    if (credentials != nil)  {
      editEmail.text = credentials?.email;
      editPassword.text = credentials?.password
    }
    
    updateView();
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    auth?.removeStateDidChangeListener(listenerHandle);
    self.navigationController?.isNavigationBarHidden = navigationBarHiddenState
    isLoggingIn = false;
    }

  func showProgressView(progress : Bool){
    workingView.isHidden = !progress
    loginForm.isHidden = progress
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //Hud.on(self);
    // Do any additional setup after loading the view, typically from a nib.
    
    ButtonStyler.style(buttonSignIn)
    ButtonStyler.style(buttonForgotPassword)
    
    auth = FIRAuth.auth()
    
    let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
    let credentials = appDelegate.getSavedCredentials()
    if credentials != nil && allowAutoLogin && (credentials?.email.characters.count)! > 0{
      
      doLogin((credentials?.email)!, password: (credentials?.password)!)
    } else if (credentials != nil) && !allowAutoLogin {
      editEmail.text = credentials?.email;
      editPassword.text = credentials?.password
      //Hud.off(self);
    } else {
      //Hud.off(self);
    }


    
    // ATTENTION: This was auto-generated to implement the App Indexing API.
    // See https://g.co/AppIndexing/AndroidStudio for more information.
    //client = new GoogleApiClient.Builder(this).addApi(AppIndex.API).build();
  }
  
  func attemptLogin(){
    let rememberMe = checkRememberMe.isOn;
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    if !rememberMe{
      appDelegate.resetCredentials()
    }
    
    let email = editEmail.text
    let password = editPassword.text
    var cancel = false;
    
    if TextUtils.isEmpty(password!) || !isPasswordValid(password: password!){
      UiUtility.showAlert("Password", message: "This passwod is too short", presenter: self)
      cancel = true;
    } else if TextUtils.isEmpty(email!){
      UiUtility.showAlert("Email", message: "The email address is required", presenter: self);
      cancel = true;
    } else if !TextUtils.isValidEmail(email: email!){
      UiUtility.showAlert("Email", message: "This email address is invalid", presenter: self);
      cancel = true;
    }

    if cancel{
      return;
    }
  
   // TODO validate eamil and password to be 
    // sure no errors
    //Hud.on(self);
    doLogin(email!, password: password!);
    
  }
  
  
  
  func lookupDatabaseUser(_ firebaseUser : FIRUser) -> Void{
    
    let uid = firebaseUser.uid;
    usersReference  = FIRDatabase.database().reference(withPath: "/users/\(uid)")
    usersReference?.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
      if !snapshot.exists(){
        UiUtility.showAlert("Unexpected Error", message: "Unexpected error. User is not present; Was user deleted?", presenter: self);
        self.isLoggingIn = false;
        self.updateView();
        return
      }
      let user = User(snapshot);
      // TODO what to do about customer logins
      /*
      if user.getRole() == Role.Customer {
        UiUtility.showAlert("Permissions Restriction", message: "We're sorry, but we presently do not support Customer logins in the mobile app. Please try the web interface at https://app.speedymovinginventory.com", presenter: self)
        do {
          try self.auth?.signOut()
          self.fired = false;
          self.isLoggingIn = false;
          self.updateView()
          return
        } catch {
          UiUtility.showAlert("Unexpected Error", message: "Error: Cant read user information. Please contact support", presenter: self)
          self.isLoggingIn = false;
          self.updateView()
          return
        }
      }*/
      
      let appDelegate  = UIApplication.shared.delegate as! AppDelegate;
      appDelegate.currentUser = user;
      
      if self.checkRememberMe.isOn {
        let loginCredentials = LoginCredentials(email: self.editEmail.text!, password: self.editPassword.text!);
        appDelegate.saveCredentials(loginCredentials)
      }
      DispatchQueue.main.async  {
        
        let sb = self.storyboard!

    
        let vc = (sb.instantiateViewController(withIdentifier: "ChooseCompanyViewController"))
        self.navigationController?.pushViewController(vc, animated: true);
      }
      
    });
    
  }
  
  func doLogin(_ email: String, password : String){
    //showProgressView(progress: true)
    isLoggingIn = true;
    updateView();
    auth?.signIn(withEmail: email, password: password, completion:
    {(user, error) in
      //self.showProgressView(progress: false);
      if error != nil{
        //Hud.off(self);
        
        UiUtility.showAlert("Login Failed", message: (error?.localizedDescription)!, presenter: self)
        self.fired = false;
        self.isLoggingIn = false;
        self.updateView();
      }
    })
  }
  
  func updateView(){
    loginForm.isHidden = isLoggingIn;
    workingView.isHidden = !isLoggingIn;
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    
  @IBAction func signInPressed(_ sender: AnyObject) {
    attemptLogin()
  }

  @IBAction func forgotPasswordPressed(_ sender: AnyObject) {
    //launchForgotPasswordViewController();
  }
  /// text field delegate
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool // return NO to disallow editing.
  {
    
    return true;
  }
  func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
  {
    //super.textFieldDidBeginEditing(textField)
    activeTextField = textField;
  }
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
  {
    return true;
  }
  func textFieldDidEndEditing(_ textField: UITextField) // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
  {
    //super.textFieldDidEndEditing(textField)
    
  }
  
  
  func textField(_ textField: UITextField,
                 shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool{
    if string.characters.count == 0{
      return true;
    }
       return true;
  }
  
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
  {
    if activeTextField == editEmail{
      editPassword.becomeFirstResponder()
    } else {
      self.view.endEditing(true)
    }
    textField.resignFirstResponder()
    return true;
  }

  func isPasswordValid(password : String ) -> Bool {
    return password.characters.count > 6;
  }
 
  
}
