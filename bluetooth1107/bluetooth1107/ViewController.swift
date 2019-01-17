//
//  ViewController.swift
//  bluetooth1107
//
//  Created by Betty on 2018/11/7.
//  Copyright © 2018 Betty. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    //系統藍牙管理對象
    var manager : CBCentralManager!
    var discoverdPeripheralsArr : [CBPeripheral?] = []
    var tableView : UITableView!
    //連接的外圍
    var connectedPeripheral : CBPeripheral!
    //保存的設備特性
    var savedCharacteristic : CBCharacteristic!
    var lastString : NSString!
    var sendString : NSString!
    //需要連接的CBCharacteristic's UUID
    let ServiceUUID1 = "FFE1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create the tableview to present servers
        tableView = UITableView.init(frame:CGRect(x: 0 , y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height),style: UITableView.Style.plain)
        tableView.delegate = self;
        tableView.dataSource = self;
        self.view.addSubview(tableView)
        //Create a button when click it then show servers
        let leftButton = UIButton.init(type: UIButton.ButtonType.custom)
        leftButton.frame = CGRect(x: 0, y: 0, width: 60, height: 20)
        leftButton.setTitle("Scan Device", for: UIControl.State.normal)
        leftButton.setTitleColor(UIColor.gray, for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        leftButton.addTarget(self, action:#selector(ViewController.startScan), for: UIControl.Event.touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView:leftButton)
        //初始化
        manager = CBCentralManager.init(delegate: self,queue: DispatchQueue.main)
    }
    
    
    @objc func startScan() {
        //通過UUID人篩選設備，傳nil掃描周圍所有設備
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //寫入數據
    func viewController(_ peripheral: CBPeripheral,didWriteValueFor characteristic:CBCharacteristic,value : Data) -> () {
        //當characteristic.properties 有write權限才可寫入
        if characteristic.properties.contains(CBCharacteristicProperties.write) {
            //寫入時有回饋
            self.connectedPeripheral.writeValue(value, for: characteristic, type: .withResponse)
        }
        else {
            print("Error write")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController : UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoverdPeripheralsArr.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellId")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cellId")
        }
        let peripheral = discoverdPeripheralsArr[indexPath.row]
        if((peripheral?.name) != nil) {
            cell?.textLabel?.text = String.init(format: "service name :%@", (peripheral?.name)!)
            
        }
        else {
            cell?.textLabel?.text = "No name"
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeripheral = discoverdPeripheralsArr[indexPath.row]
        manager.connect(selectedPeripheral!, options: nil)
    }
}

extension ViewController :CBCentralManagerDelegate,CBPeripheralDelegate {
    //掃描外圍設備
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        case .poweredOff:
            print("CBCentralManagerStatePowerOff")
        case .poweredOn:
            print("CBCentralManagerStatePowerOn")
        }
    }
    
    //When find the device then use this method
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //Use app:lightblue to imitate device
        print("Discovered = ", peripheral.identifier, " at ", RSSI, "name", peripheral.name ?? "")
        var isExisted = false
        for obtainedPeriphal in discoverdPeripheralsArr {
            if(obtainedPeriphal?.identifier == peripheral.identifier) {
                isExisted = true
            }
        }
        
        if !isExisted {
            discoverdPeripheralsArr.append(peripheral)
        }
        
        tableView.reloadData()
    }
    
    //連接上外圍設備
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        //外圍設備尋找peripheral的service
        peripheral.discoverServices(nil)
        
        peripheral.delegate = self
        self.title = peripheral.name
        //停止掃描
        manager .stopScan()
        
        let alertController = UIAlertController.init(title: "Connected \(peripheral.name)", message: nil, preferredStyle: .alert)
        
        self.present(alertController, animated: true) {
            alertController.dismiss(animated: false, completion: {
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                //連接後跳轉
                let valueController = storyboard.instantiateViewController(withIdentifier:"InputValueViewController") as! InputValueViewController
                self.present(valueController, animated: true, completion: nil)
                //將value傳回到lightblue
                valueController.inputValueBlock = { (sendStr) -> () in
                    self.sendString = sendStr as NSString!
                    let data = sendStr.data(using: .utf8)
                    
                    self.viewController(self.connectedPeripheral, didWriteValueFor: self.savedCharacteristic, value: data!)
                }
            
            })
        }
        
    }
    
    //連接Peripgerals失敗
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name) this device, because \(error?.localizedDescription)")
    }
    
    //斷開
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnect to \(peripheral.name) this device, because \(error?.localizedDescription)")
        
        let alertView = UIAlertController.init(title:"SORRY", message: "bluetooth device\(peripheral.name) is disconnect,please scan the device again", preferredStyle: UIAlertController.Style.alert)
    }
    
    //掃描到Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print("When search services, \(peripheral.name) has error \(error?.localizedDescription)")
        }
        //外圍設備(peripheral)需要一個UUID確定需要連接的服務，對應service的UUID，而不是為外圍設備的UUID
        for service in peripheral.services! {
            //需要連接的CBCharacteristic's UUID
            if service.uuid.uuidString == ServiceUUID1 {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    //掃描到characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("When search characteristics, \(peripheral.name) has error \(String(describing: error?.localizedDescription))")
        }
        for characteristic in service.characteristics! {
            peripheral.readValue(for: characteristic)
            
            //設置characteristic的notifying屬性為true，表示接受廣播
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    //獲取characteristic的值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(characteristic.value != nil) {
            let resultStr = NSString(data: characteristic.value!, encoding:String.Encoding.utf8.rawValue)
            print("characteristic uuid:\(characteristic.uuid)   value:\(resultStr)")
            
            if lastString == resultStr {
                return;
            }
        }
        //保存操作的characteristic
        self.savedCharacteristic = characteristic
    }
    
    //This method is invoked only when your app cslls the writeValue(_:for:type:) method with the withResponse constant specified as the write type.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("When write value for characteristics, \(peripheral.name) has error \(error?.localizedDescription)")
        }
        
        let alertView = UIAlertController.init(title: "Sorry", message: " It work!",preferredStyle:UIAlertController.Style.alert)
        let cancelAction = UIAlertAction.init(title:"OK", style: .cancel, handler: nil)
        alertView.addAction(cancelAction)
        alertView.show(self, sender: nil)
        lastString = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
    }
}
