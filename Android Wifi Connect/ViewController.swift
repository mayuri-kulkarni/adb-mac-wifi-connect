//
//  ViewController.swift
//  Android Wifi Connect
//
//  Created by Chetan Gangurde on 24/04/20.
//  Copyright © 2020 Mayuri Kulkarni. All rights reserved.
//

import Cocoa
import Network


class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tableMasterView: NSScrollView!
    @IBOutlet weak var noDeviceFoundLabel: NSTextField!
    var data:[String] = []
    var scannedDevicesOutput : String = ""
    var tcpPortConnectOutput : String = ""

    var scannedDevices : [Substring] = []
    let adbScanDevicesCommand = "devices"
    let adbPath :String = "~/Library/Android/sdk/platform-tools/adb"
    let validIpAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

    
    @IBOutlet weak var adbPathTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.action = nil
        adbPathTextField.stringValue = adbPath
        tcpPortConnectOutput = shell(launchPath: adbPath, arguments: [ "disconnect"])
        print(tcpPortConnectOutput)
        checkDevicesAndStart()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    @IBAction func refreshClicked(_ sender: Any) {
        checkDevicesAndStart()
    }
    
    //MARK:- IP address
    
    func checkIfIp(strRawTarget: String)->Bool{
        
        print(strRawTarget)
        if (IPv4Address(strRawTarget) != nil){
            return true

        }
//        if strRawTarget.rangeOfString(validIpAddressRegex, options: .RegularExpressionSearch) {
//        //println("\(strRawTarget) is a valid IP address")
//            return true
//        }
        return false
    }
    //MARK:- Commands For ADB
    func checkDevicesAndStart(){
        scannedDevicesOutput = shell(launchPath: adbPath, arguments: [ "devices"])
        print(scannedDevicesOutput)
        scannedDevices = scannedDevicesOutput.split(separator: "\n")
        scannedDevices.remove(at: 0)
        
        print(scannedDevices)
        if  scannedDevices.count <= 0 {
            tableView.reloadData()
            noDeviceFoundLabel.isHidden = false
            tableMasterView.isHidden = true
        return
        }
        noDeviceFoundLabel.isHidden = true
        tableMasterView.isHidden = false

       
               tcpPortConnectOutput = shell(launchPath: adbPath, arguments: [ "tcpip","5555"])
               print(tcpPortConnectOutput)
            data = []
            print("device available")
            for scanDeviceid in scannedDevices{
                let deviceid = scanDeviceid.split(separator: "\t")[0]
                print(deviceid)
                if( checkIfIp(strRawTarget: String(deviceid.split(separator: ":")[0]))){
                    return
                }
                // remove devices with ip address
                data.append(String(deviceid))
            }
        

        tableView.reloadData()
        
    }


    func shell(launchPath: String, arguments: [String]) -> String {
        let launchPathS = adbPathTextField.stringValue
        let process = Process()
        process.launchPath = launchPathS
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let output_from_command = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
        //        // remove the trailing new-line char
        //        if output_from_command.count > 0 {
        //            let lastIndex = output_from_command.index(before: output_from_command.endIndex)
        //            let startI = output_from_command.startIndex
        //            return output_from_command[output_from_command.startIndex..<lastIndex]
        //        }
        return output_from_command
    }
}



//MARK:- tableView Setup
extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "devicesColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "devicesCell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = data[row]
            return cellView
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "connectColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "connectCell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            let view = cellView.viewWithTag(0) as! NSButton
            view.tag = row
//            print(tableColumn?.dataCell(forRow: row))
            view.action = #selector(onButtonClicked(v:))
            return cellView
            
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "ipAddrColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "ipAddrCell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
    
            return cellView
            
        } else {
            
        }
        return nil
    }
    
  

    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        print(tableColumn)
    }
    
    //MARK:- Handle clicks
    @objc private func onButtonClicked(v: NSButton) {
          
          let index = v.tag
          print(v.tag)
        if connectTo(index: index){
            v.state = .on
            v.stringValue = "connected"
        }
      
          
      }
    
    func connectTo( index : Int)->Bool{
        let column = tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ipAddrColumn") )
        print(column)
        guard let cellView = tableView.view(atColumn: column, row: index, makeIfNecessary: false)as? NSTableCellView
        else { return false }
        let view = cellView.viewWithTag(0) as! NSTextField
        print(view.stringValue)
       
        tcpPortConnectOutput = shell(launchPath: adbPath, arguments: [ "connect","\(view.stringValue):5555"])
        print(tcpPortConnectOutput)
        if tcpPortConnectOutput.contains("connected"){
            // show aler or something
            return true
        }
        return false
        
    }
}



