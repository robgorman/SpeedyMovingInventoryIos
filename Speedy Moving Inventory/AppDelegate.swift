//
//  AppDelegate.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var user : User?
  var currentUser : User?{
    set {
      user = newValue;
      FIRDatabase.database().reference(withPath:"companies/" + (newValue?.companyKey)!)
        .observe(FIRDataEventType.value, with: {(snapshot) in
          self.currentCompany = Company(snapshot)
        })
    }
    get {
      return user;
    }
  }

  var currentCategory : Category?
  
  var currentCompany : Company?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    // init firebase
    FIRApp.configure();
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  func resetCredentials(){
    let defaults = UserDefaults.standard
    defaults.set(nil, forKey:"email")
    defaults.set(nil, forKey:"password")
    
  }
  
  func saveCredentials(_ credentials : LoginCredentials){
    let defaults = UserDefaults.standard
    defaults.set(credentials.email, forKey:"email")
    defaults.set(credentials.password, forKey:"password")
  }
  
  func getSavedCredentials() -> LoginCredentials?{
    let defaults = UserDefaults.standard
    let email = defaults.string(forKey: "email")
    let password = defaults.string(forKey: "password")
    if (email != nil){
      return LoginCredentials(email: email!, password: password!)
    } else {
      return nil
    }
    
  }


}

