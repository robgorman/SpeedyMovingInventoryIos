//
//  AppDelegate.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/29/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import UIKit
import Firebase
import AlamofireImage
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  

  var user : User?
  var currentUser : User?  

  var currentCategory : Category?
  
  var currentCompany : Company?
  var userCompanyAssignment : UserCompanyAssignment?
  
  var count  = 0
  var initializationDone = false;
  
  var movingItemDescriptions : [String : [MovingItemDataDescription]] = [:];
  
  var storageUrl : String?
  var webAppUrl : String?
  var mailServer : Server?
  
  
  func getListFor(room : Room) -> [MovingItemDataDescription]{
    return movingItemDescriptions[room.rawValue]!;
  }
  
  func loadMovingItemDescriptions(){
    let roomLists = FIRDatabase.database().reference(withPath: "speedyMovingItemDataDescriptions/");
    roomLists.observe(.childAdded, with: {(snapshot) -> Void in
      
      
      for next in snapshot.children {
        let nextSnap = next as! FIRDataSnapshot;
        let itemDataDescription = MovingItemDataDescription(nextSnap)
        var itemsSoFar : [MovingItemDataDescription]? = self.movingItemDescriptions[itemDataDescription.room!];
        if (itemsSoFar == nil){
          itemsSoFar = [];
        }
        itemsSoFar?.append(itemDataDescription)
        self.movingItemDescriptions[itemDataDescription.room!] = itemsSoFar

      }
      self.initializationDone = true;

      /*
      
      let itemListForRoom = FIRDatabase.database().reference(withPath: "speedyMovingItemDataDescriptions/" + snapshot.key)
      itemListForRoom.observe(.childAdded, with: {(snapshot) -> Void in
        let itemDataDescription = MovingItemDataDescription(snapshot)
        var itemsSoFar : [MovingItemDataDescription]? = self.movingItemDescriptions[itemDataDescription.room!];
        if (itemsSoFar == nil){
          itemsSoFar = [];
        }
        itemsSoFar?.append(itemDataDescription)
        self.movingItemDescriptions[itemDataDescription.room!] = itemsSoFar
        })
     
      self.count = self.count + 1;
      if (self.count == 14 ){
        self.initializationDone = true;
      }
 */

    })
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    // init firebase
    FIRApp.configure();
    UIApplication.shared.isNetworkActivityIndicatorVisible = false;
    loadMovingItemDescriptions();
    
    // enable IQKeyboardManagerSwift
    IQKeyboardManager.sharedManager().enable = true;
    
    // this changes based on dev or prod
    // TODO this should be put into build target or config, etc
    // There must be a better way
    #if DEVELOPMENT
      storageUrl = "gs://speedymovinginventorydev-9c905.appspot.com"
      webAppUrl = "https://speedymovinginventorydev-9c905.firebaseapp.com"
    #else
      storageUrl = "gs://speedymovinginventory.appspot.com"
      webAppUrl = "https://app.speedymovinginventory.com"

    #endif
    
    mailServer = Server(baseUrl: "https://speedymovinginventory.appspot.com");
    
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

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    var vc2 : UIViewController? = nil;
    let vc = UIApplication.shared.keyWindow?.rootViewController;
    if vc is UINavigationController{
      let nc = vc as! UINavigationController
      vc2 = nc.presentedViewController;
    }
    //let vc2 = vc?.presentedViewController
    //let win = self.;
    //let root = win?.rootViewController;
    //let vc = root?.presentedViewController;
    //let vc2 = root?.presentingViewController;
    
    if vc is SignOffViewController || vc2 is SignOffViewController{
      
      return UIInterfaceOrientationMask.portrait;
      
    } else {
      return UIInterfaceOrientationMask.all;
    }
    
  }
  

}

