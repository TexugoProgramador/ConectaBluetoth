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
    var peripheralSelecionado: CBPeripheral?
    
    var dispositivoSelecionado = CBPeripheral.self
    
    var serviceCBUUID = CBUUID()
    
    var characteristicCriada:CBCharacteristic?
    
    @IBOutlet weak var tabelaDispositivos: UITableView!
    @IBOutlet weak var tabelaPesagens: UITableView!
    
    var arrayPesagem = Array<String>()
    
    var podeLer = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        tabelaDispositivos.delegate = self
        tabelaDispositivos.dataSource = self
        
        tabelaPesagens.delegate = self
        tabelaPesagens.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(carregaTabela(notification:)), name: NSNotification.Name(rawValue: "carregaTabela"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(carregaTabelaPesagem(notification:)), name: NSNotification.Name(rawValue: "carregaTabelaPesagem"), object: nil)
    }
    
    @objc func carregaTabela(notification: Notification!) {
        DispatchQueue.main.async {
            self.tabelaDispositivos.reloadData()
        }
    }
    
    @objc func carregaTabelaPesagem(notification: Notification!) {
        DispatchQueue.main.async {
            self.tabelaPesagens.reloadData()
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
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {// se o tipo de componente permitir a leitura
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.contains(.write){
                characteristicCriada = characteristic
                print("\(characteristic.uuid): Escreve comando")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let characteristicData = characteristic.value else { return }
        
        let byteArray = [UInt8](characteristicData)
        leituraDeDados(dadosRecebido: byteArray)
    }
    
    func limparPesagem() {
        var arr: [UInt8] = [0x05, 0x02, 0x00, 0x50, 0x00, 0x00, 0xae, UInt8.max]
        let data = Data(buffer: UnsafeBufferPointer(start: &arr, count: arr.count))
        peripheralSelecionado?.writeValue(data, for: characteristicCriada!, type: CBCharacteristicWriteType.withResponse)
    }
    
    @IBAction func comecarPesagem(_ sender: UIButton) {
        var arr: [UInt8] = [0x05, 0x02, 0x00, 0x50, 0x00, 0x00, 0xae, UInt8.max]
        let data = Data(buffer: UnsafeBufferPointer(start: &arr, count: arr.count))
        peripheralSelecionado?.writeValue(data, for: characteristicCriada!, type: CBCharacteristicWriteType.withResponse)
    }
    
    
    func leituraDeDados(dadosRecebido: [UInt8]) {
        if dadosRecebido.count >= 20 {
            if dadosRecebido[17] == 70 {
                if podeLer {
                    let pesoAnimal = dadosRecebido[8...14]
                    exibePeso(pesoBalanca: pesoAnimal)
                    sleep(1)
                    limparPesagem()
                }
                podeLer = false
            }else{
                podeLer = true
            }
        }
    }
    
    func exibePeso(pesoBalanca: ArraySlice<UInt8>) {
        let stringPeso = String(bytes: pesoBalanca, encoding: .utf8)
        arrayPesagem.append(stringPeso ?? "sem pesagem")
        NotificationCenter.default.post(name: NSNotification.Name("carregaTabelaPesagem"), object: nil)
    }
    
}

extension BlueToothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tabelaDispositivos {
            return peripherals.count
        }else{
            return arrayPesagem.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == tabelaDispositivos {
            let cell = tabelaDispositivos.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let peripheralTemp = peripherals[indexPath.row]
            cell.textLabel?.text = peripheralTemp.name
            cell.detailTextLabel?.text = "\(peripheralTemp.identifier)"
            return cell
        }else{
            let cell = tabelaPesagens.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let pesoTemp = arrayPesagem[indexPath.row]
            cell.textLabel?.text = pesoTemp
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tabelaDispositivos {
            peripheralSelecionado = peripherals[indexPath.row]
            centralManager!.connect(peripheralSelecionado!)
        }
    }
    
}
