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
    var orderNums = [String: [String]]()
    var attendees = [String]()
    var scanned = [String]()
    
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

                if isValid(data: code, compare: [String](self.orderNums.keys)){
                    let order = self.orderNums[code]!
                    if (Int(order[1])! > 1) {
//                        Have option to select number of tickets being scanned
                        print("to be done")
                    }
                    let output = order[0] + "\n Quantity: " + order[1] + "\n" + order[2]
                    let alertController = UIAlertController(title: "Valid ticket", message:
                           output, preferredStyle: .alert)
                       alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                               action in
                               self.scannerView.startScanning()
                           }))
//                       remove from list here
                    self.orderNums.removeValue(forKey: code)
                    self.scanned.append(code)
                       self.present(alertController, animated: true, completion: nil)
                }else{
                    var message_text = "Invalid ticket"
                    if (self.scanned.contains(code)){
                        message_text = "Ticket already scanned"
                    }
                    let alertController = UIAlertController(title: message_text, message:
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
    
    func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }
    
    func readDataFromCSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            var contents = try String(contentsOfFile: filepath, encoding: .utf8)
            contents = cleanRows(file: contents)
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(!isKeyPresentInUserDefaults(key: "attendees")){
            print("Initialized")
            let arr = "0"
            self.defaults.set(arr, forKey: "attendees")
            if (self.attendees.count != 0) {
                self.attendees = self.defaults.stringArray(forKey: "attendees")!
            }
        } else {
            if (self.attendees.count != 0) {
                self.attendees = self.defaults.stringArray(forKey: "attendees")!
            }
        }
        var data = readDataFromCSV(fileName: "Afrogala", fileType: ".csv")
        data = cleanRows(file: data!)
        let csvRows = csv(data: data!)
        
        for row in csvRows {
            if (row[0] != "") {
                let pointsArr = row[0].components(separatedBy: ",")
//              Values represent - name, ticket quantity, ticket type
                self.orderNums[pointsArr[7]] = [pointsArr[2], pointsArr[3], pointsArr[4]]
            }
        }
        print(self.orderNums)
        print(self.orderNums.count)
        
    }
    
    
    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ";")
            result.append(columns)
        }
        return result
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
