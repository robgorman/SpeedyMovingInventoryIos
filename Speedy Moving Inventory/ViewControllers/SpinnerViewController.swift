//
//  SpinnerViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 10/7/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import UIKit

protocol IndexSelected{
  func indexSelected(index : Int);
}

class SpinnerViewController : UITableViewController {
  
  
  var callback : IndexSelected? = nil
  
  var labels : [String] = []; // caller should fill
  var selectedIndex : Int = -1; // caller should fill -1 means no selection
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = title
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationItem.hidesBackButton = true;
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
     self.navigationItem.hidesBackButton = true;
  }
  
  // DATA Source
  open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
    let count = labels.count
    return count;
  }
  
  
  open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
    let cell = tableView.dequeueReusableCell(withIdentifier: "SpinnerTableCell") as! SpinnerTableCell
   
    if indexPath.row == selectedIndex{
      cell.imageView?.image = UIImage(named: "spinner_selected")
    } else {
      cell.imageView?.image = UIImage(named: "spinner_not_selected");
    }
    
    cell.label.text = self.labels[indexPath.row];
    return cell;
    
  }
  
  
  override func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath){
    
    selectedIndex = indexPath.row;
    tableView.reloadData()
    callback?.indexSelected(index: selectedIndex)
    
    Utility.delay(delaySeconds: 0.1, closure: {
      var _ = self.navigationController?.popViewController(animated: true)
    })
  }
  

}
