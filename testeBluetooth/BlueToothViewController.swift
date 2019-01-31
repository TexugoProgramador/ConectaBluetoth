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
    var centralManager: CBCentralManager!
    var peripherals = Array<CBPeripheral>()
    
    var dispositivoSelecionado = CBPeripheral.self
    
    var serviceCBUUID = CBUUID()
    
    @IBOutlet weak var tabelaDispositivos: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        tabelaDispositivos.delegate = self
        tabelaDispositivos.dataSource = self
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(carregaTabela(notification:)), name: NSNotification.Name(rawValue: "carregaTabela"), object: nil)
    }
    
    @objc func carregaTabela(notification: Notification!) {
        DispatchQueue.main.async {
            self.tabelaDispositivos.reloadData()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }else{
            print("Estado diferente de ON")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals.append(peripheral)
        NotificationCenter.default.post(name: NSNotification.Name("carregaTabela"), object: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        if serviceCBUUID.uuidString == "" {
            print("serviceCBUUID vazio")
        }else{
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(error ?? "Erro")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let servicos = peripheral.services else {
            print("Erro")
            return
        }
        for servico in servicos {
            serviceCBUUID = servico.uuid
            peripheral.discoverCharacteristics(nil, for: servico)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let caracteristicas = service.characteristics else { return }
        
        for characteristic in caracteristicas {
            print(characteristic)
            
            if characteristic.properties.contains(.read) {
//                print("\(characteristic.uuid): Da para fazer leitura")
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {// se o tipo de componente permitir a leitura  configura o setNotifyValue
//                print("\(characteristic.uuid): Recebe notificações")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.contains(.write){
//                print("\(characteristic.uuid): Escreve comando")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let characteristicData = characteristic.value else { return }
        
        let byteArray = [UInt8](characteristicData)
        leituraDeDados(dadosRecebido: byteArray)
    }
    
    func leituraDeDados(dadosRecebido: [UInt8]) {
        print(dadosRecebido)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row]
        centralManager!.connect(peripheral)
    }
    
}
