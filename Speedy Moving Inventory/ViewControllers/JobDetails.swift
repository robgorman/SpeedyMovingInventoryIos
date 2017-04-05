//
//  JobDetails.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 9/30/16.
//  Copyright © 2016 Speedy Moving Inventory. All rights reserved.
//

import Foundation
import Firebase
import Alamofire
import AlamofireImage


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

class JobDetails : UIViewController,UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, IJobConsumer, UIGestureRecognizerDelegate, IItemDeletePressed{
  
  var user : User!;
  
  
  var recipientListQuery : FIRDatabaseQuery!;
  
  @IBOutlet weak var labelNoItemsMessage: UILabel!
  @IBOutlet weak var itemCollectionView: UICollectionView!
  
  @IBOutlet weak var labelSortBy: UILabel!
  @IBOutlet weak var buttonSortBy: UIButton!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  
  var queries : [SortBy] = [];
  var currentQuery : Int = 0;
  var recipients : [User] = [];
  var jobKey : String!  // caller will provide
  var companyKey : String! // caller will provide
  var job : Job!;
  
  var currentItemQuery : FIRDatabaseQuery!
  
  var items : [ItemAndKey] = [];
  
  var isLoadingFirstTime = true;
  
  var deleteMode = false;
  
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
    .queryStarting(atValue: companyKey)
    .queryEnding(atValue: companyKey)
    
    setupQueries()
    currentQuery = 0
    //queryForItems(queries[currentQuery]);
//    
//    let database = FIRDatabase.database();
//    let q = database.reference(withPath: "itemlists/" + jobKey);
//    q.observe(FIRDataEventType.value, with: {(snapshot) in
//      if snapshot.exists{
//        updateControlVisibility
//      }
//    })

    isLoadingFirstTime = true;
    handleControlVisibility(0);
    
    let longPressGestureRecogizer = UILongPressGestureRecognizer(
      target : self,
      action: #selector(self.handleLongPress(gestureRecognizer:)))
    
    longPressGestureRecogizer.minimumPressDuration = 0.5;
    longPressGestureRecogizer.delegate = self;
    longPressGestureRecogizer.delaysTouchesBegan = true;
    self.itemCollectionView.addGestureRecognizer(longPressGestureRecogizer);

  }
  
  
  func handleBeginDeleteMode(){
    self.deleteMode = true;
    itemCollectionView.reloadData();
  }
  
  func handleEndDeleteMode(){
    deleteMode = false;
    itemCollectionView.reloadData();
  }

  
  
  func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
    
    if job.getLifecycle() != Lifecycle.New{
      UiUtility.showAlert("Delete Unavailable", message: "Deletion is not allowed when the Job Status is not New.", presenter: self)
    } else {
      
      
      switch (gestureRecognizer.state){
      case .began:
        print("began");
        handleBeginDeleteMode();
      case .cancelled:
        print("cancelled");
      case .changed:
        print("changed");
      case .ended:
        print("ended")
      //handleEndDeleteMode();
      case .failed:
        print("falied")
      case .possible:
        print("possible)")
      }
    }
    
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
    //print("This is run on fthe background queue")
    
    ///DispatchQueue.main.async {
    //print("This is run on the main queue, after the previous code in outer block")
    //}
    //}
    queryForItems(queries[currentQuery]);

    
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
    if (isLoadingFirstTime){
      labelNoItemsMessage.isHidden = true;
      itemCollectionView.isHidden = true;
      labelSortBy.isHidden = true;
      buttonSortBy.isHidden = true;
      loadingIndicator.isHidden = false;
    } else {
      loadingIndicator.isHidden = true;
   
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

  }
  
  func queryForItems(_ sortBy : SortBy){
    buttonSortBy.setTitle(sortBy.sortBy + "  >", for: .normal)
   
    if currentItemQuery != nil{
      currentItemQuery.removeAllObservers();
    }
    currentItemQuery = sortBy.query;
    currentItemQuery.observe(FIRDataEventType.value, with: {(snapshot) in
      self.isLoadingFirstTime = false;
      let enumerator = snapshot.children;
      self.items.removeAll();
      self.handleControlVisibility(snapshot.childrenCount)
      while let next = enumerator.nextObject() as? FIRDataSnapshot{
        
        let item = Item(next)
        let key = next.key
        self.items.append(ItemAndKey(key: key, item: item));
      }
      DispatchQueue.main.async {
        self.itemCollectionView.reloadData();

      }
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
    vc.title = "Choose A Sort"
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
      vc.companyKey = self.companyKey;
      vc.itemWasCreatedOutOfPhase = false; 
      
      self.navigationController?.pushViewController(vc, animated: true);
    } else {
      let vc = (self.storyboard?.instantiateViewController(withIdentifier: "ItemClaimViewController")) as! ItemClaimViewController;
      vc.jobKey = jobKey
      vc.qrcCode = itemAndKey.key;
      vc.lifecycle = job.getLifecycle();
      self.navigationController?.pushViewController(vc, animated: true);
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
    let itemAndKey = items[indexPath.row]
    if deleteMode {
      handleEndDeleteMode();
    } else {
      launchItemDetailsView(itemAndKey: itemAndKey)
    }
   
  }
  // Swift 3.0
  //func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
 //   return CGSize(width: CGFloat((collectionView.frame.size.width / 3) - 20), height: //CGFloat(100))
 // }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    // 3 or 5 depending on device screen width
    var numberOfColumnsInPortrait : CGFloat = 3.0;
    if self.traitCollection.horizontalSizeClass == .compact{
      numberOfColumnsInPortrait = 3.0;
    } else {
      numberOfColumnsInPortrait = 5.0 ;
    }
    let w1 = Float(UIScreen.main.bounds.size.width)
    let w2 = Float(UIScreen.main.bounds.size.height)
    let width = min(w1, w2);
    let w = Float(width);
    print("\(w2) \(w1) \(w)")
    let cellWidth = (CGFloat(width) / numberOfColumnsInPortrait) - 5 ;
    print(cellWidth)
    let cellHeight = (cellWidth * 175/125) - 5
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
      let currencyFormatter = NumberFormatter();
      currencyFormatter.maximumFractionDigits = 2
      currencyFormatter.numberStyle = NumberFormatter.Style.currency
      
      cell.sortLabel.text = currencyFormatter.string(from: NSNumber(value:item.getMonetaryValue()))
    case 1: //volume
      let s = String(item.getVolume()) + " ft3"
      cell.sortLabel.attributedText = TextUtils.formFt3Superscript(text: s)
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
    
    cell.containerView.layer.borderWidth = 1.0;
    cell.containerView.layer.borderColor = Colors().lightGrey.cgColor
    cell.containerView.layer.cornerRadius = 1;
    cell.containerView.clipsToBounds = true;
    
    if item.imageReferences != nil && (item.imageReferences?.count)! >= 2{
      cell.moreImagesLabel.isHidden = false;
      let numstr = String(describing: item.imageReferences!.count - 1);
      cell.moreImagesLabel.text = numstr + " more";
    } else {
      cell.moreImagesLabel.isHidden = true;
    }
    
    cell.deleteButton.isHidden = !deleteMode;
    if (deleteMode){
      
      
      let transformAnim  = CAKeyframeAnimation(keyPath:"transform")
      transformAnim.values  = [NSValue(caTransform3D: CATransform3DMakeRotation(0.04, 0.0, 0.0, 1.0)),NSValue(caTransform3D: CATransform3DMakeRotation(-0.04 , 0, 0, 1))]
      transformAnim.autoreverses = true
      let answer = Double(indexPath.row).truncatingRemainder(dividingBy: 2.0);
      transformAnim.duration  = (answer == 0 ) ?   0.115 : 0.105
      transformAnim.repeatCount = Float.infinity
      cell.containerView.layer.add(transformAnim, forKey: "transform")
    } else {
      cell.containerView.layer.removeAllAnimations();
    }
    
    cell.index = indexPath.row;
    cell.callback = self;
    
    return cell;
    
  }
  
  func deleteItem(_ indexPath : Int){
   
    // how to delete an item?
    let itemAndKey = items[indexPath];
    let itemKey = itemAndKey.key;
    let item = itemAndKey.item;
    removeItem(companyKey: companyKey, jobKey: jobKey, itemKey: itemKey, imageReferences: item.imageReferences! )
    handleEndDeleteMode();
  }
  
  func removeItem(companyKey : String, jobKey : String, itemKey : String, imageReferences : NSDictionary){
    FIRDatabase.database().reference(withPath: "/itemlists/" + jobKey + "/items/" + itemKey).removeValue();

    FIRDatabase.database().reference(withPath: "/qrcList/" + itemKey).removeValue();
    
    let storage = FIRStorage.storage();
    let appDelegate = UIApplication.shared.delegate as! AppDelegate;
    let storageRef = storage.reference(forURL: appDelegate.storageUrl!);
    for (key, _) in imageReferences{
      let keyString = key as! String;
      var path = "/images/" + companyKey + "/";
      path = path +  jobKey + "/" + itemKey ;
      path = path + "/" + keyString
      // TODO this causes exception
      //storageRef.child(path).delete();
    }
  }
  
  // TODO this might be why iphone is so slow. 
  
  func loadImage(_ item : Item, cell : ItemCollectionCell) {
    if item.imageReferences != nil && (item.imageReferences?.count)! > 0 {
      let keys = item.imageReferences?.allKeys;
      var keysArray = Array(keys!);
      let key = keysArray[0];
      let urlString = item.imageReferences?[key] as! String;
      //let url = URL(string: urlString)
      let url = URL(string: urlString);
      
    
      // THIS is the AlamoFire Image example handy dandy loader. it gets cached etc.
      
      cell.itemImageView.af_setImage(withURL : url!, placeholderImage : UIImage(named:"noimage"))
      
/*
      imageDownloader.download([urlRequest]) {response in
        debugPrint(response)
        print(response.request!)
        print(response.response!)
        debugPrint(response.result)
        if let image = response.result.value {
          cell.itemImageView.image = image; 
          print("image downloaded: \(image)")
          
        }
      }
 */
    } else if item.getIsBox()  {
      cell.itemImageView.image = UIImage(named: "closedbox")
    } else {
      cell.itemImageView.image = UIImage(named:"noimage");
    }

      /*
      do {
        
        let uiImage = try UIImage(data: Data(contentsOf: url!));
        cell.itemImageView.image = uiImage;
      } catch {
        cell.itemImageView.image = UIImage(named:"noimage");
      }
      */
      
      }
  // prefetch
  
  open func jobUpdate(_ job : Job){
  
    self.job = job;
    updateFromJob()
  }
  
  func updateFromJob(){
    // TODO
  }
  
 }


