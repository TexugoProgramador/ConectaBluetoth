//
//  ViewController.swift
//  testeBluetooth
//
//  Created by humberto Lima on 21/01/19.
//  Copyright © 2019 humberto Lima. All rights reserved.
//

import UIKit
import CoreBluetooth

//    https://www.bluetooth.com/specifications/gatt/services
//    https://www.bluetooth.com/specifications/gatt/characteristics

class ViewController: UIViewController, CBCentralManagerDelegate {
    
    @IBOutlet weak var labelStatus: UILabel!
    
    var centralManager: CBCentralManager!
    
    let serviceCBUUID = CBUUID(string: "0x1800")
    var devicePeripheral: CBPeripheral!
    
    let characteristicCBUUID1 = CBUUID(string: "2A38")
    let characteristicCBUUID2 = CBUUID(string: "2A37")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePeripheral.delegate = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            labelStatus.text = "Status: unknown"
        case .resetting:
            labelStatus.text = "Status: resetting"
        case .unsupported:
            labelStatus.text = "Status: unsupported"
        case .unauthorized:
            labelStatus.text = "Status: unauthorized"
        case .poweredOff:
            labelStatus.text = "Status: poweredOff"
        case .poweredOn:
            labelStatus.text = "Status: poweredOn"
            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        devicePeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(devicePeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado com Device!")
        peripheral.discoverServices([serviceCBUUID])// procura pelos servicos disponivel o tipo de conexão
    }
    
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
       
        guard let servicos = peripheral.services else { return }
        for servico in servicos {
            //lista todos os serviços disponiveis do dispositivo
            print(servico)
            peripheral.discoverCharacteristics(nil, for: servico)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let caracteristicas = service.characteristics else { return }
        
        for characteristic in caracteristicas {
            print(characteristic)
         
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): Da para fazer leitura")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {// se o tipo de componente permitir a leitura  configura o setNotifyValue
                print("\(characteristic.uuid): Recebe notificações")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
       
        switch characteristic.uuid {
        case characteristicCBUUID1: // verifica se o dispositivo tem a caracterista que passei no começo do projeto
            let componenteConectado = leituraDoComponente(from: characteristic)
            print(componenteConectado)// vai dar um print com os valores para "Byte" do componente
            print(characteristic.value ?? "Sem valores")
            
        case characteristicCBUUID2:
            let valorRecebido = leituraDoComponente(from: characteristic)
            print(valorRecebido)
            print(characteristic.value ?? "Sem valores")
            
        default:
            print("ID não reconhecido: \(characteristic.uuid)")
        }
    }
    
    private func leituraDoComponente(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
            let byte = characteristicData.first else { return "Error" }
        
        // faz a leitura dos dados do componente em questão
        // no exemplo bodyLocation tem 7 opções
        switch byte {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
    
    private func leituraDAdosComponente(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01 // cria uma variavel para o primeiro bit da resposta
       
        if firstBitValue == 0 {
            return Int(byteArray[1])
        } else {
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    
    
}
