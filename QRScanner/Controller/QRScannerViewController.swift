//
//  QRScannerViewController.swift
//  QRCodeReader
//
//  Created by KM, Abhilash a on 08/03/19.
//  Copyright © 2019 KM, Abhilash. All rights reserved.
//

import UIKit

class QRScannerViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var attendees = [String]()
    
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
        }
    }
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.setTitle("STOP", for: .normal)
        }
    }
    
    
    @IBAction func importData(_ sender: Any) {

        let alert = UIAlertController(title: "Restricted action", message: "Please enter admin password", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = ""
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if(textField?.text == "password"){
                                
                let alert = UIAlertController(title: "Sensitive action", message: "Please enter new data", preferredStyle: .alert)

                alert.addTextField { (textField) in
                    textField.text = ""
                }

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                    let arr = textField?.text?.components(separatedBy: ",")
                    self.defaults.set(arr, forKey: "attendees")
                    self.attendees = self.defaults.stringArray(forKey: "attendees")!
                    self.showToast(message : "Data updated successfully")
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in
                    self.showToast(message : "Action cancelled")
                }))

                self.present(alert, animated: true, completion: nil)
                
            }else{
                self.showToast(message : "Incorrect password")
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    var qrData: QRData? = nil {
        didSet {
            if qrData != nil {
                
                let code = String(qrData!.codeString!.split(separator: "-")[1])
                
                if isValid(data: code, compare: self.attendees){
                    let alertController = UIAlertController(title: "Valid ticket", message:
                           code, preferredStyle: .alert)
                       alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                               action in
                               self.scannerView.startScanning()
                           }))

                       self.present(alertController, animated: true, completion: nil)
                }else{
                    let alertController = UIAlertController(title: "Unvalid ticket", message:
                            code, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                                action in
                                self.scannerView.startScanning()
                            }))

                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!isKeyPresentInUserDefaults(key: "attendees")){
            print("Initialized")
            let arr = "0"
            self.defaults.set(arr, forKey: "attendees")
            self.attendees = self.defaults.stringArray(forKey: "attendees")!
        }else{
            self.attendees = self.defaults.stringArray(forKey: "attendees")!
        }
        
    }
    
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }

    @IBAction func scanButtonAction(_ sender: UIButton) {
        scannerView.isRunning ? scannerView.stopScanning() : scannerView.startScanning()
        let buttonTitle = scannerView.isRunning ? "STOP" : "SCAN"
        sender.setTitle(buttonTitle, for: .normal)
    }
}


extension QRScannerViewController: QRScannerViewDelegate {
    func qrScanningDidStop() {
        let buttonTitle = scannerView.isRunning ? "STOP" : "SCAN"
        scanButton.setTitle(buttonTitle, for: .normal)
    }
    
    func qrScanningDidFail() {
        presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again")
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        self.qrData = QRData(codeString: str)
    }
    
    
    
}

func isValid(data: String, compare: [String]) -> Bool {
    if(compare.contains(data)){
        return true
    }
    return false
}

func isKeyPresentInUserDefaults(key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}
