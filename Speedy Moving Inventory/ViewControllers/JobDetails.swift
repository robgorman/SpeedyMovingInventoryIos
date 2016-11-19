//
//  JobDetails.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase



class SortBy{
  var query : FIRDatabaseQuery
  var sortBy : String
  init(query : FIRDatabaseQuery, sortBy : String){
    self.query = query
    self.sortBy = sortBy
  }
}

class ItemAndKey{
  var key : String
  var item : Item;
  init(key : String, item : Item){
    self.key = key;
    self.item = item;
  }
}

class JobDetails : UIViewController,UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, IJobConsumer{
  
  var user : User!;
  
  
  var recipientListQuery : FIRDatabaseQuery!;
  
  @IBOutlet weak var labelNoItemsMessage: UILabel!
  @IBOutlet weak var itemCollectionView: UICollectionView!
  
  @IBOutlet weak var labelSortBy: UILabel!
  @IBOutlet weak var buttonSortBy: UIButton!
  
  var queries : [SortBy] = [];
  var currentQuery : Int = 0;
  var recipients : [User] = [];
  var jobKey : String!  // caller will provide
  var job : Job!;
  
  var currentItemQuery : FIRDatabaseQuery!
  
  var items : [ItemAndKey] = [];
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.edgesForExtendedLayout = []
    // self.edgesForExtendedLayout = UIRectEdge.none
    assert(jobKey != nil)
    let delegate = UIApplication.shared.delegate as! AppDelegate
    user = delegate.currentUser;
    assert(user != nil)

    recipientListQuery = FIRDatabase.database().reference(withPath: "users/")
    .queryOrdered(byChild: "companyKey")
    .queryStarting(atValue: user.companyKey)
    .queryEnding(atValue: user.companyKey)
    
    setupQueries()
    currentQuery = 0
    queryForItems(queries[currentQuery]);

    
  }
  
  let  sortReverse = [true, true, false, false, true, true]
  
  func setupQueries(){
    let database = FIRDatabase.database();
    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "monetaryValueInverse"), sortBy: "By Value"))
    
    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "volumeInverse"), sortBy: "By Volume"))

    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "category"), sortBy: "By Category"))
  
    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "isScanned"), sortBy: "By Scanned"))
    
    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "weightLbsInverse"), sortBy: "By Weight"))
    
    queries.append(SortBy(query: database.reference(withPath:"itemlists/" + jobKey + "/items")
      .queryOrdered(byChild: "isClaimActiveInverse"), sortBy: "By Claim"))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    
    //DispatchQueue.global(qos: .background).async {
    //print("This is run on the background queue")
    
    ///DispatchQueue.main.async {
    //print("This is run on the main queue, after the previous code in outer block")
    //}
    //}
    
      self.recipientListQuery.observe(FIRDataEventType.value, with: {(snapshot) in
        print(snapshot.childrenCount);
        //self.items = [];
        let enumerator = snapshot.children
        while let next = enumerator.nextObject() as? FIRDataSnapshot{
          let user = User(next)
          
          //  let key = next.key;
          self.recipients.append(user);
          
        }
      })
    
  }
  
  
  override func viewWillDisappear(_ animated: Bool) {
   
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func handleControlVisibility(_ itemCount : UInt){
    if itemCount == 0 {
      labelNoItemsMessage.isHidden = false;
      itemCollectionView.isHidden = true;
      labelSortBy.isHidden = true;
      buttonSortBy.isHidden = true;
    } else {
      labelNoItemsMessage.isHidden = true;
      itemCollectionView.isHidden = false;
      labelSortBy.isHidden = false;
      buttonSortBy.isHidden = false;

    }

  }
  
  func queryForItems(_ sortBy : SortBy){
    buttonSortBy.setTitle(sortBy.sortBy + "  >", for: .normal)
   
    if currentItemQuery != nil{
      currentItemQuery.removeAllObservers();
    }
    currentItemQuery = sortBy.query;
    currentItemQuery.observe(FIRDataEventType.value, with: {(snapshot) in
      let enumerator = snapshot.children;
      self.items = []
      self.handleControlVisibility(snapshot.childrenCount)
      while let next = enumerator.nextObject() as? FIRDataSnapshot{
        
        let item = Item(next)
        let key = next.key
        self.items.append(ItemAndKey(key: key, item: item));
      }
      self.itemCollectionView.reloadData();
    })
    
  }
  
  class SortByCallback : IndexSelected{
    var outer : JobDetails
    init(vc : JobDetails){
      outer = vc;
    }
    
    func indexSelected(index: Int) {
      outer.currentQuery = index;
      outer.queryForItems( outer.queries[outer.currentQuery])
    }
  }
  @IBAction func sortByPressed(_ sender: AnyObject) {
    
    let vc = (self.storyboard?.instantiateViewController(withIdentifier: "SpinnerViewController")) as! SpinnerViewController;
    
    
    var labels : [String] = [];
    for next in queries{
      let s = next.sortBy
      labels.append(s)
    }
    vc.labels = labels;
    vc.selectedIndex = currentQuery;
    vc.title = "Choose Sort"
    vc.callback = SortByCallback(vc: self)
    
    self.navigationController?.pushViewController(vc, animated: true);
    
  }


  // data soruce

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
    let count = items.count;
    return count
  }
  
  func launchItemDetailsView(itemAndKey : ItemAndKey){
    if (job.getLifecycle() == Lifecycle.New){
      let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
      vc.jobKey = jobKey
      vc.qrcCode = itemAndKey.key;
      self.navigationController?.pushViewController(vc, animated: true);
    } else {
      let vc = (self.storyboard?.instantiateViewController(withIdentifier: "ItemClaimViewController")) as! ItemClaimViewController;
      vc.jobKey = jobKey
      vc.qrcCode = itemAndKey.key;
      self.navigationController?.pushViewController(vc, animated: true);
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
    let itemAndKey = items[indexPath.row]
    launchItemDetailsView(itemAndKey: itemAndKey)
   
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let cellWidth = collectionView.bounds.size.width/3;
    print(cellWidth)
    let cellHeight = cellWidth * 132/125
    print(cellHeight)
    return CGSize(width: cellWidth, height: cellHeight);
  }
  
  // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCollectionCell", for: indexPath) as!
       ItemCollectionCell;
    
    let itemAndKey = items[indexPath.row]
    let item = itemAndKey.item
    
    loadImage(itemAndKey.item, cell: cell)
    cell.itemDescription.text = itemAndKey.item.desc
    
    cell.imageCheckMark.isHidden = !item.getIsScanned()
    cell.imageDamageWarning.isHidden = !item.getHasClaim()
    
    cell.sortLabel.isHidden = false;
    switch currentQuery {
    case 0:
      cell.sortLabel.text = "$" + String(item.getMonetaryValue())
    case 1: //volume
      cell.sortLabel.text = String(item.getVolume()) + " ft3"
    case 2: //category
      cell.sortLabel.text = item.category
    case 3: // scanned
      cell.sortLabel.isHidden = true;
    case 4: // weight
      cell.sortLabel.text = String(item.getWeightLbs()) + " lbs"
    case 5: // claim
      cell.sortLabel.isHidden = true;
    default:
      cell.sortLabel.text = "$" + String(item.getMonetaryValue())
    }
    
    return cell;
    
  }
  
  func loadImage(_ item : Item, cell : ItemCollectionCell) {
    if item.imageReferences != nil && (item.imageReferences?.count)! > 0 {
      let keys = item.imageReferences?.allKeys;
      var keysArray = Array(keys!);
      let key = keysArray[0];
      let urlString = item.imageReferences?[key] as! String;
      let url = URL(string: urlString)
      
      do {
        let uiImage = try UIImage(data: Data(contentsOf: url!));
        cell.itemImageView.image = uiImage;
      } catch {
        cell.itemImageView.image = UIImage(named:"noimage");
      }
      
      
    } else if item.getIsBox()  {
      cell.itemImageView.image = UIImage(named: "closedbox")
    } else {
      cell.itemImageView.image = UIImage(named:"noimage");
    }
  }
  // prefetch
  
  open func jobUpdate(_ job : Job){
  
    self.job = job;
    updateFromJob()
  }
  
  func updateFromJob(){
    // TODO
  }
  
/*
  let vc = (self.storyboard?.instantiateViewController(withIdentifier: "EditItemViewController")) as! EditItemViewController;
  vc.jobKey = jobKey
  vc.qrcCode = code;
  codeReaderViewContoller.navigationController?.pushViewController(vc, animated: true);
*/
}
