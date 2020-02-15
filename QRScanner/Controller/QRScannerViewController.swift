//
//  QRScannerViewController.swift
//  QRCodeReader
//
//  Created by KM, Abhilash a on 08/03/19.
//  Copyright © 2019 KM, Abhilash. All rights reserved.
//

//To handle multiple events
//when generating ordernums list - go through and split into event one and event 2
//Give user an option to select which event they're scanning for
//Check based on that list

//Diff ticket type include
//Show + Food
//Afterparty
//Show + Food + Afterparty

//two lists - if we get a "both" on one of the list - update the other accordingly - does not work - need three lists
// need to accomodate for choosing which to remove if they have multiple of diff types

//so if we have 3 lists - one for each type - and we have a user who has a couple of each
//When scanned - all 3 types and their quantities should come up
//have a way for the scanner to select which to subtract tickets from
//e.g 2 show + food and 3 show + food + afterparty
// have two text boxes, one on top of the other in format - label - box - scanner can input how many of each to scan and we can take those figures and then update the lists accordingly, instead of having separate dictionary, give each another value in their list representing number of tickets scanned.

//currently have swapped out order nums for currentlist - need to swap out scanned as we have that stored in the current one - then we need to display multiple tickets on scanning and their quantity - then we need to look at removing multiple of them (here we'll add the user input text box at this point) - then we look at having the tab to select which event they are currently scanning (maybe a toggle button)

//FIX PROBLEM WHERE USER STOPS APP RUNNING IN THE BACKGROUND - MAY HAVE TO STORE DB STUFF ON EXTERNAL SERVER
//after this - add confirmation message when multiple tickets are scanned (like with one ticket)
//move people counter down
//deploy on link

import UIKit

class QRScannerViewController: UIViewController {

    let defaults = UserDefaults.standard
    var numberPeopleScanned = 0
    var orderNums = [String: [String]]()
    var mainEvent = [String: [String]]()
    var afterParty = [String: [String]]()
    var both = [String: [String]]()
    var attendees = [String]()
    var scanned = [String: [String]]()
    var currEvent = EventType.MAINEVENT
    
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
                var otherList = [String: [String]]()
                print(comparisonList)
                print(self.mainEvent)
                if (self.currEvent == EventType.MAINEVENT) {
                    comparisonList = self.mainEvent
                    otherList = self.afterParty
                } else {
                    comparisonList = self.afterParty
                    otherList = self.afterParty
                }
                print("Current comparison list")
                print(comparisonList)
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
                    
                    if (Int(order[1])! == 1) {
                        self.numberPeopleScanned += 1
                    }
                    
                    if (Int(order[1])! > 1) {
                   
                        let titleText = "Valid ticket"
                        let messageText = showCustomerTickets(code: code, isInvalid: false) + "\n Please enter the number you would like to scan off this ticket or alternatively click 'Scan all'"
                        
                        let ac = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
                        ac.addTextField()
                        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
                            
                            let answer = ac.textFields![0]
                            if (Int(answer.text!) == nil) {
                                quantity = 0
                            } else {
                                quantity = Int(answer.text!)!
                            }
                            if !(self.scanned.keys.contains(code)) {
                                var zeroList = comparisonList[code]
                                zeroList![1] = "0"
                                self.scanned[code] = zeroList
                            }

                            if (quantity == Int(order[1])) {
                                self.scanned[code] = comparisonList[code]
                                comparisonList.removeValue(forKey: code)
                                self.numberPeopleScanned += quantity
                            }
                            else if ((quantity + Int(self.scanned[code]![1])! <= Int(order[1])!)) {
                                var newList = self.scanned[code]
                                newList![1] = String((Int(newList![1]) ?? 0) + quantity)
                                self.scanned.updateValue(newList!, forKey: code)
                                
                                if (self.scanned[code]![1] == comparisonList[code]![1]) {
                                    comparisonList.removeValue(forKey: code)
                                }
                                self.numberPeopleScanned += quantity
                            }
                                
                            else {
                                var ticketsLeft = ""
                                if (self.scanned.keys.contains(code)) {
                                    ticketsLeft = String(Int(order[1])! - Int(self.scanned[code]![1])!)
                                } else {
                                    ticketsLeft = order[1]
                                }
                                let tooManyTicketsAlert = UIAlertController(title: "Invalid amount", message: "Customer only has " + ticketsLeft + " tickets left", preferredStyle: UIAlertController.Style.alert)
                                tooManyTicketsAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: nil))
                                self.present(tooManyTicketsAlert, animated: true, completion: nil)
                            }
                            self.numTicketsScanned.text = String(self.numberPeopleScanned)
                        }
                        
                        let scanAllAction = UIAlertAction(title: "Scan all", style: .default) {  _ in
                        
                            var quantity = 0
                            if (comparisonList.keys.contains(code)) {
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
                    print(self.numberPeopleScanned)
                }else{
                    var message_text = "Invalid ticket"
                    var output = code

                    if (comparisonList.keys.contains(code) || self.both.keys.contains(code)){
                        if (comparisonList[code]![3] == comparisonList[code]![1] || self.both[code]![3] == self.both[code]![1]) {
                            message_text = "Ticket already scanned"
                            output = showCustomerTickets(code: code, isInvalid: true)
                        }
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
                let code = pointsArr[7]
                let valuesList = [pointsArr[2], pointsArr[3], pointsArr[4], "0"]
//              Values represent - name, ticket quantity, ticket type, number tickets scanned
                self.orderNums[pointsArr[7]] = valuesList
                if (valuesList[2] == "Afterparty only") {
                    self.afterParty[code] = valuesList
                }
                if (valuesList[2] == "Show + Food") {
                    self.mainEvent[code] = valuesList
                }
                if (valuesList[2] == "Show + Afterparty + Food") {
                    self.both[code] = valuesList
                }
            }
        }
        print(self.both)
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
        if (self.currEvent == EventType.MAINEVENT) {
            order = self.mainEvent[code]!
        } else {
            order = self.afterParty[code]!
        }
        var left: Int
        if !(isInvalid) {
            left = Int(order[1])! - Int(order[3])!
        } else {
            left = Int(order[1])!
        }

        var output = order[0] + "\n" + order[2] + ": " + String(left)
        if (self.both.keys.contains(code)) {
            order = self.both[code]!
            var left: Int
            if !(isInvalid) {
                left = Int(order[1])! - Int(order[3])!
            } else {
                left = Int(order[1])!
            }
            output += "\n" + order[2] + ": " + String(left)
        }
        return output
    }
    
    func isValid(data: String, compare: [String: [String]]) -> Bool {
        if(compare.keys.contains(data) || self.both.keys.contains(data)){
            return (compare[data]![1] > compare[data]![3] || self.both[data]![1] > self.both[data]![3])
        }
        return false
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
