//
//  MovingItemPickViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 11/22/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation


protocol IMovingItemPicked {
  func picked(_ description : MovingItemDataDescription, category: Category)
}

class MovingItemPickViewController : UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
  
  @IBOutlet weak var fillterTextField: UITextField!
  @IBOutlet weak var changeRoomButton: UIButton!
  @IBOutlet weak var itemTableView: UITableView!
  @IBOutlet weak var cancelButton: UIButton!
  
  // input params
  var roomString : String!
  var allowCancel : Bool!
  var callback : IMovingItemPicked!
  var category : Category!
  //////////////////////////
  
  
  var originalItemList : [MovingItemDataDescription]!;
  var filteredItemList : [MovingItemDataDescription]!;
  var selectedIndex = -1; //neg is no selection. 
  
  var lastFilterLength = 0;
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "Choose An Item"
    
    // always allow cancel for now
    allowCancel = true;
    
    changeRoomButton.setTitle(category.rawValue + " >", for: .normal)
    if !allowCancel {
      self.navigationItem.hidesBackButton = true
      cancelButton.isHidden = true;
    }
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    originalItemList = appDelegate.getListFor(room: Room(rawValue:roomString)!)
    filteredItemList = appDelegate.getListFor(room:  Room(rawValue:roomString)!)
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
  }
  // DATA Source
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{

    return filteredItemList.count;
  }

  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
    let cell = tableView.dequeueReusableCell(withIdentifier: "MovingItemPickTableCell") as! MovingItemPickTableCell
    
    if selectedIndex == indexPath.row{
      cell.checkedImage.image = UIImage(named: "spinner_selected")
    } else {
      cell.checkedImage.image = UIImage(named: "spinner_not_selected")
    }
    cell.label.text = filteredItemList[indexPath.row].itemName;
    
    return cell;
    
  }
  

  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath){
    // going to go back to caller. lots of data
    // to return;
    selectedIndex = indexPath.row;
    let item = filteredItemList[indexPath.row];
    itemTableView.reloadData();
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
      self.callback.picked(item, category: self.category);
      // TODO retru
      var _ = self.navigationController?.popViewController(animated: true)
    })
  }
  @IBAction func changeRoomPressed(_ sender: Any) {
    launchChooseRoomSpinner();
  }

  @IBAction func cancelPressed(_ sender: Any) {
    // cancel result and pop back
    // TODO
    var _ = self.navigationController?.popViewController(animated: true)
  }
  
  class RoomCallback : IndexSelected{
    var outer : MovingItemPickViewController
    init(vc : MovingItemPickViewController){
      outer = vc;
    }
    
    func indexSelected(index: Int) {
      outer.category = Category.allValues[index];
      var categoryString = Category.allValues[index].rawValue;
      
      //outer.roomString = categoryString;
      //outer.roomString = Room.allValues[index].rawValue;
      outer.changeRoomButton.setTitle(categoryString + " >", for: .normal)
      
      // convert categoryString to Room
      if categoryString.contains("Bedroom"){
        categoryString = "Bedroom";
      }
      var i = 0;
      var roomIndex = 0;
      for room in Room.allValues{
        if room.rawValue == categoryString{
          roomIndex = i;
          break;
        } else {
          i = i + 1;
        }
      }
      outer.roomString = Room.allValues[roomIndex].rawValue
      let appDelegate = UIApplication.shared.delegate as! AppDelegate
      outer.originalItemList = appDelegate.getListFor(room: Room.allValues[roomIndex])
      outer.filteredItemList = appDelegate.getListFor(room: Room.allValues[roomIndex])
      outer.itemTableView.reloadData()
    }
  }
  
  func launchChooseRoomSpinner(){
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SpinnerViewController")) as! SpinnerViewController;
  
    var labels : [String] = [];
    for next in Category.allValues{
      labels.append(next.rawValue)
    }
    vc.labels = labels;
    
    let label = self.category.rawValue;
    let i = labels.index(of: label)
    vc.selectedIndex = i!
    vc.title = "Choose a Room"
    vc.callback = RoomCallback(vc: self)
    
    self.navigationController?.pushViewController(vc, animated: true);
  }
  
  func filter(list : [MovingItemDataDescription], filterString : String){
    if filterString.characters.count == 0{
      for item in list{
        filteredItemList.append(item);
      }
    } else {
    filteredItemList = [];
      for item in list{
        let lowerCaseFilter = filterString.lowercased()
        if item.itemName?.lowercased().range(of : lowerCaseFilter) != nil{
          filteredItemList.append(item);
        }
      }
    }
    
  }
  
  func filter(filterString : String){
    var copy : [MovingItemDataDescription]
    if filterString.characters.count > lastFilterLength{
      copy = filteredItemList;
    } else {
      copy = originalItemList;
    }
    lastFilterLength = filterString.characters.count;
    filter (list: copy, filterString: filterString)
    itemTableView.reloadData();
  }
  
  @IBAction func filterTextChanged(_ sender: UITextField) {
    filter(filterString: sender.text!);
  }
  

}
