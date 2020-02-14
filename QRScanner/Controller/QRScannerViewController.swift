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
    var numberPeopleScanned = 0
    var orderNums = [String: [String]]()
    var attendees = [String]()
    var scanned = [String: [String]]()
    
    @IBOutlet weak var numTicketsScanned: UILabel!
    @IBOutlet weak var ticketsScannedLabel: UILabel!
   
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

    var qrData: QRData? = nil {
        didSet {
            if qrData != nil {
                let code = String(qrData!.codeString!.split(separator: "-")[1])
                self.numTicketsScanned.text = String(self.numberPeopleScanned)

                if isValid(data: code, compare: [String](self.orderNums.keys)){
                    let order = self.orderNums[code]!
                    var quantity = 0
            
                    let output = order[0] + "\n Quantity: " + order[1] + "\n" + order[2]
                    let alertController = UIAlertController(title: "Valid ticket", message:
                           output, preferredStyle: .alert)
                       alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                               action in
                               self.scannerView.startScanning()
                           }))
                    
                    if (Int(order[1])! == 1) {
                        self.numberPeopleScanned += 1
                    }
                    
                    if (Int(order[1])! > 1) {
                        var ticketsLeft = ""
                        if (self.scanned.keys.contains(code)) {
                            ticketsLeft = String(Int(order[1])! - Int(self.scanned[code]![1])!)
                        } else {
                            ticketsLeft = order[1]
                        }
                        let titleText = "Customer has " + ticketsLeft + " tickets left, how many would you like to scan in?"
                        
                        let ac = UIAlertController(title: titleText, message: nil, preferredStyle: .alert)
                        ac.addTextField()
                        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
                            
                            let answer = ac.textFields![0]
                            if (Int(answer.text!) == nil) {
                                quantity = 0
                            } else {
                                quantity = Int(answer.text!)!
                            }
                            if !(self.scanned.keys.contains(code)) {
                                var zeroList = self.orderNums[code]
                                zeroList![1] = "0"
                                self.scanned[code] = zeroList
                            }

                            if (quantity == Int(order[1])) {
                                self.scanned[code] = self.orderNums[code]
                                self.orderNums.removeValue(forKey: code)
                                self.numberPeopleScanned += quantity
                            }
                            else if ((quantity + Int(self.scanned[code]![1])! <= Int(order[1])!)) {
                                var newList = self.scanned[code]
                                newList![1] = String((Int(newList![1]) ?? 0) + quantity)
                                self.scanned.updateValue(newList!, forKey: code)
                                
                                if (self.scanned[code]![1] == self.orderNums[code]![1]) {
                                    self.orderNums.removeValue(forKey: code)
                                }
                                self.numberPeopleScanned += quantity
                            }
                                
                            else {
                                let tooManyTicketsAlert = UIAlertController(title: "Invalid amount", message: "Customer only has " + ticketsLeft + " tickets left", preferredStyle: UIAlertController.Style.alert)
                                tooManyTicketsAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                                self.present(tooManyTicketsAlert, animated: true, completion: nil)
                            }
                            self.numTicketsScanned.text = String(self.numberPeopleScanned)
                        }
                        ac.addAction(submitAction)
                        present(ac, animated: true)
                    }
                    self.present(alertController, animated: true, completion: nil)
                    print(self.numberPeopleScanned)
                }else{
                    var message_text = "Invalid ticket"
                    var output = code
                    if (self.scanned.keys.contains(code)){
                        message_text = "Ticket already scanned"
                        let order = self.scanned[code]!
                        output = order[0] + "\n Quantity: " + order[1] + "\n" + order[2]
                    }
                    let alertController = UIAlertController(title: message_text, message:
                            output, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                                action in
                                self.scannerView.startScanning()
                            }))

                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            self.numTicketsScanned.text = String(self.numberPeopleScanned)
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
        view.addSubview(ticketsScannedLabel)
        self.numTicketsScanned.text = "0"
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
