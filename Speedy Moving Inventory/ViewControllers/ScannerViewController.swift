//
//  ScannerViewController.swift
//  Speedy Moving Inventory
//
//  Created by rob gorman on 4/7/17.
//  Copyright © 2017 Speedy Moving Inventory. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox

/**
 The result of the scan with its content value and the corresponding metadata type.
 */
public struct ScannerResult {
  /**
   The error corrected data decoded into a human-readable string.
   */
  public let value: String
  
  /**
   The type of the metadata.
   */
  public let metadataType: String
}

public class ScannerViewController : UIViewController {
  // optional input params
  var prompt : String?
  //var cameraView   = ReaderOverlayView()
  //var cameraView   = UIView!

  @IBOutlet weak var checkMark: UIImageView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var nextScanButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var toggleTorchButton: UIButton!
  /// The code reader object used to scan the bar code.
  var codeReader: ScannerCodeReader!
  
  var visible = true;
  // MARK: - Managing the Callback Responders
  
  /// The receiver's delegate that will be called when a result is found.
  public weak var delegate: ScannerViewControllerDelegate?
  
  /// The completion blocak that will be called when a result is found.
  public var completionBlock: ((ScannerResult?) -> Void)?
  
  deinit {
    codeReader.stopScanning()
    
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Creating the View Controller
  
  public override func viewDidLoad(){
    super.viewDidLoad()
    if prompt == nil{
      prompt = "Point Camera at QR Code";
    }
    messageLabel.text = prompt;
    codeReader = ScannerCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode]);
    view.backgroundColor = .black
    codeReader.didFindCode = { [weak self] resultAsObject in
      if let weakSelf = self {
        weakSelf.completionBlock?(resultAsObject)
        weakSelf.delegate?.reader(weakSelf, didScanResult: resultAsObject)
      }
      self?.stopScanning()
    }
    
    cameraView.layer.insertSublayer(codeReader.previewLayer, at: 0)
    
    NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }
  
  
  // MARK: - Responding to View Events
  override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return parent?.supportedInterfaceOrientations ?? .all
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    nextScanButton.isHidden = true;
    checkMark.isHidden = true;
   
    startScanning()
    
    cameraView.clipsToBounds = true;
    codeReader.previewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)

    visible = true;
    self.navigationController?.isNavigationBarHidden = true;
  }
  
  override public func viewWillDisappear(_ animated: Bool) {
    stopScanning()
    visible = false;
    super.viewWillDisappear(animated)
    self.navigationController?.isNavigationBarHidden = false;
  }
  
  override public func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    codeReader.previewLayer.frame = view.bounds
  }
  
  // MARK: - Managing the Orientation
  
  func orientationDidChanged(_ notification: Notification) {
    cameraView.setNeedsDisplay()
    
    if let device = notification.object as? UIDevice , codeReader.previewLayer.connection.isVideoOrientationSupported {
      codeReader.previewLayer.connection.videoOrientation = ScannerCodeReader.videoOrientation(deviceOrientation: device.orientation, withSupportedOrientations: supportedInterfaceOrientations, fallbackOrientation: codeReader.previewLayer.connection.videoOrientation)
    }
  }
  
  // MARK: - Controlling the Reader
  
  /// Starts scanning the codes.
  public func startScanning() {
    codeReader.startScanning()
  }
  
  /// Stops scanning the codes.
  public func stopScanning() {
    codeReader.stopScanning()
  }
  
  public func showNext(){
    nextScanButton.isHidden = false;
  }
  
  // MARK: - Catching Button Events
  
  @IBAction func toggleTorchPressed(_ sender: Any) {
    codeReader.toggleTorch()
  }

  @IBAction func nextScannPressed(_ sender: Any) {
    startScanning()
    nextScanButton.isHidden = true;
    checkMark.isHidden = true;
    messageLabel.text = "Point Camera at QR Code."
  }
  
  func endScan(){
    codeReader.stopScanning()
    
    if let _completionBlock = completionBlock {
      _completionBlock(nil)
    }
    
    //delegate?.readerDidCancel(self)
    let _ = self.navigationController?.popViewController(animated: true);
    
    //self.dismiss(animated: true, completion: nil)

  }
  
  @IBAction func endScanPressed(_ sender: Any) {
    endScan()
  }
  
  func switchCameraAction(_ button: SwitchCameraButton) {
    codeReader.switchDeviceInput()
  }
  
}

/**
 This protocol defines delegate methods for objects that implements the `QRCodeReaderDelegate`. The methods of the protocol allow the delegate to be notified when the reader did scan result and or when the user wants to stop to read some QRCodes.
 */
public protocol ScannerViewControllerDelegate: class {
  /**
   Tells the delegate that the reader did scan a code.
   
   - parameter reader: A code reader object informing the delegate about the scan result.
   - parameter result: The result of the scan
   */
  func reader(_ reader: ScannerViewController, didScanResult result: ScannerResult)
  
  /**
   Tells the delegate that the user wants to stop scanning codes.
   
   - parameter reader: A code reader object informing the delegate about the cancellation.
   */
  func readerDidCancel(_ reader: ScannerViewController)
}

