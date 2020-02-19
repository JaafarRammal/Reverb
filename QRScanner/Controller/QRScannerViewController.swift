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
//    These dicts to be refactored to a list containing them which may be iterated over (in the transition between accessing a db)
    var orderNums = [String: [String]]()
    var mainEvent = [String: [String]]()
    var afterParty = [String: [String]]()
    var both = [String: [String]]()
    
    var attendees = [String]()
    var scanned = [String: [String]]()
    var currEvent = EventType.AFTERPARTY
    
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
                var comparisonList = [String: [String]]()
//                var otherList = [String: [String]]()
                var onlyBoth = false
                
//                This code will be removed as we will be displaying all events
                if (self.currEvent == EventType.MAINEVENT) {
                    comparisonList = self.mainEvent
//                    otherList = self.afterParty
                } else {
                    comparisonList = self.afterParty
//                    otherList = self.afterParty
                }
                if !(comparisonList.keys.contains(code)) {
                    comparisonList = self.both
                    onlyBoth = true
                }
                
                
                if isValid(data: code, compare: comparisonList){
                 
                    let order = comparisonList[code]!
                    var quantity = 0
                    let output = showCustomerTickets(code: code, isInvalid: false)

                    let alertController = UIAlertController(title: "Valid ticket", message:
                           output, preferredStyle: .alert)
                       alertController.addAction(UIAlertAction(title: "Okay", style: .default,handler: {
                               action in
                               self.scannerView.startScanning()
                           }))
                    
                    if ((Int(order[1])! -  Int(order[3])!) == 1) {
                        if (onlyBoth) {
                            self.both[code]![3] = order[1]
                        } else {
                            if (self.currEvent == EventType.MAINEVENT) {
                                self.mainEvent[code]![3] = order[1]
                            } else {
                                self.afterParty[code]![3] = order[1]
                            }
                        }
                        self.numberPeopleScanned += 1
                    }
                    
                    if (Int(order[1])! > 1) {
                   
                        let titleText = "Valid ticket"
                        let messageText = showCustomerTickets(code: code, isInvalid: false) + "\n Please enter the number you would like to scan off this ticket or alternatively click 'Scan all'"
                        
                        let ac = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
                        if !(onlyBoth) {
                            ac.addTextField() { (textField) in
                                textField.placeholder = "No. of show and food tickets to scan?"
                            }
                        }
                        
                        if (self.both.keys.contains(code)) {
                            ac.addTextField() { (textField) in
                                textField.placeholder = "No. of combo tickets to scan?"
                            }
                        }

                        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
                            let mainVal = ac.textFields![0]
                            var mainAnswer = 0
                            if (Int(mainVal.text!) == nil) {
                                mainAnswer = 0
                            } else {
                                mainAnswer = Int(mainVal.text!)!
                            }
                            
                            let mainScan = Int(order[3])! + mainAnswer
                            
                            var bothAnswer = 0
                            var bothScan = 0

                            if (self.both.keys.contains(code)) {
                                var textField = 0
                                if !(onlyBoth) {
                                    textField = 1
                                }
                                let bothVal = ac.textFields![textField]

                                if (Int(bothVal.text!) == nil) {
                                    bothAnswer = 0
                                } else {
                                    bothAnswer = Int(bothVal.text!)!

                                }
                                bothScan = Int(self.both[code]![3])! + bothAnswer
                            }
                            if (onlyBoth) {
                                mainAnswer = 0
                            }
                            quantity += mainAnswer
                            quantity += bothAnswer

                            var comboValid = true
                            if (self.both.keys.contains(code)){
                                comboValid = bothScan <= Int(self.both[code]![1])!
                            }

                            if (mainScan <= Int(order[1])! && comboValid) {
                                if (self.both.keys.contains(code)) {
                                    self.both[code]![3] = String(Int(self.both[code]![3])! + bothAnswer)
                                }
                                
                                if (!onlyBoth) {
                                    if (self.currEvent == EventType.MAINEVENT ) {
                                        self.mainEvent[code]![3] = String(Int(self.mainEvent[code]![3])! + mainAnswer)
                                    } else {
                                        self.afterParty[code]![3] = String(Int(self.afterParty[code]![3])! + mainAnswer)
                                    }
                                }

                                self.numberPeopleScanned += quantity
                            } else {
                                let tooManyTicketsAlert = UIAlertController(title: "Invalid amount", message: "Customer does not have that many tickets left, please re-scan", preferredStyle: UIAlertController.Style.alert)
                                tooManyTicketsAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                                self.present(tooManyTicketsAlert, animated: true, completion: nil)
                            }
                            self.numTicketsScanned.text = String(self.numberPeopleScanned)
                        }
                        
                        let scanAllAction = UIAlertAction(title: "Scan all", style: .default) {  _ in
                        
                            var quantity = 0
                            if !(comparisonList == self.both) {
                                if (self.currEvent == EventType.MAINEVENT) {
                                    quantity += Int(self.mainEvent[code]![1])! - Int(self.mainEvent[code]![3])!
                                    self.mainEvent[code]![3] = self.mainEvent[code]![1]
                                } else {
                                    quantity += Int(self.afterParty[code]![1])! - Int(self.afterParty[code]![3])!
                                    self.afterParty[code]![3] = self.afterParty[code]![1]
                                }
                            }
                            if (self.both.keys.contains(code)) {
                                quantity += Int(self.both[code]![1])! - Int(self.both[code]![3])!
                                self.both[code]![3] = self.both[code]![1]

                            }
                            self.numberPeopleScanned += quantity
                            self.numTicketsScanned.text = String(self.numberPeopleScanned)

                            
                            let sc = UIAlertController(title: "All tickets scanned", message: nil, preferredStyle: .alert)
                            let scanned = UIAlertAction(title: "Continue", style: .default) {  _ in
                            }
                            sc.addAction(scanned)
                            self.present(sc, animated: true)
                        }
                        ac.addAction(scanAllAction)
                        ac.addAction(submitAction)
                        present(ac, animated: true)
                    }
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    var message_text = "Invalid ticket"
                    var output = code
                                        
                    if (comparisonList.keys.contains(code) || self.both.keys.contains(code)){
                        message_text = "Ticket already scanned"
                        output = showCustomerTickets(code: code, isInvalid: true)
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
        var data = readDataFromCSV(fileName: "Afrogala - Ticket information", fileType: ".csv")
        data = cleanRows(file: data!)
        let csvRows = csv(data: data!)
        
        for row in csvRows {
            if (row[0] != "") {
                let pointsArr = row[0].components(separatedBy: ",")
                let code = pointsArr[7]
//              Values represent - name, ticket quantity, ticket type, number tickets scanned
                var valuesList = [pointsArr[2], pointsArr[3], pointsArr[4], "0"]
//                self.orderNums[pointsArr[7]] = valuesList
                
                if (valuesList[2] == "Afterparty only") {
                    self.afterParty[code] = valuesList
                }
                if (valuesList[2] == "Thursday show only" || valuesList[2] == "THURSDAY FLASH SALE") {
                    self.mainEvent[code] = valuesList
                }
                if (valuesList[2] == "Thursday Group of 6") {
                    valuesList[3] = "6"
                    self.mainEvent[code] = valuesList
                }
                if (valuesList[2] == "Thursday Group of 6") {
                    valuesList[3] = "6"
                    self.mainEvent[code] = valuesList
                }
                if (valuesList[2] == "Thursday Group of 6") {
                    valuesList[3] = "6"
                    self.mainEvent[code] = valuesList
                }
                if (valuesList[2] == "Show + Afterparty + Food") {
                    self.both[code] = valuesList
                }
            }
        }
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
    
    func showCustomerTickets(code: String, isInvalid: Bool) -> String {
        var order: [String]
        var left: Int
        var output = ""
        var nameSet = false
        var prevSet = false
        
            if (self.mainEvent.keys.contains(code)) {
                order = self.mainEvent[code]!
                nameSet = true
                prevSet = true
                if !(isInvalid) && prevSet {
                   left = Int(order[1])! - Int(order[3])!
               } else {
                   left = Int(order[1])!
               }
                output += order[0] + "\n" + order[2] + ": " + String(left)
            }
       
            if (self.afterParty.keys.contains(code)) {
                order = self.afterParty[code]!
                prevSet = true
                if !(isInvalid) && prevSet {
                   left = Int(order[1])! - Int(order[3])!
               } else {
                   left = Int(order[1])!
               }
                output += (nameSet ? "" : order[0]) + "\n" + order[2] + ": " + String(left)
            }
        
       
        if (self.both.keys.contains(code)) {
            order = self.both[code]!
            var left: Int
            if !(isInvalid) {
                left = Int(order[1])! - Int(order[3])!
            } else {
                left = Int(order[1])!
            }
            output += (nameSet ? "" : order[0]) + "\n" + order[2] + ": " + String(left)
        }
        return output
    }
    
    func isValid(data: String, compare: [String: [String]]) -> Bool {
        var result = false
        let dealingWithCombo = self.both.keys.contains(data)
        if(compare.keys.contains(data)){
            result = compare[data]![1] > compare[data]![3]
            if (!result && !dealingWithCombo) {
                return false
            }
        }
        
        if (self.both.keys.contains(data)) {
            result = self.both[data]![1] > self.both[data]![3] || result
        }
        return result
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

func isKeyPresentInUserDefaults(key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

enum EventType {
    case MAINEVENT
    case AFTERPARTY
}
