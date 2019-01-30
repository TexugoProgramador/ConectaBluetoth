//
//  BlueToothViewController.swift
//  testeBluetooth
//
//  Created by humberto Lima on 30/01/19.
//  Copyright © 2019 humberto Lima. All rights reserved.
//

import UIKit
import CoreBluetooth

class BlueToothViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate {

    let centralQueue: DispatchQueue = DispatchQueue(label: "", attributes: .concurrent)
    var centralManager: CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    
    @IBOutlet weak var tabelaDispositivos: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        tabelaDispositivos.delegate = self
        tabelaDispositivos.dataSource = self
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(carregaTabela(notification:)), name: NSNotification.Name(rawValue: "carregaTabela"), object: nil)
    }
    
    @objc func carregaTabela(notification: Notification!) {
        tabelaDispositivos.reloadData()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }else{
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals.append(peripheral)
        NotificationCenter.default.post(name: NSNotification.Name("carregaTabela"), object: nil)
    }
    

    
}

extension BlueToothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tabelaDispositivos.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        cell.detailTextLabel?.text = "\(peripheral.identifier)"
        return cell
    }
    
    
}
