//
//  BluetoothSerialManager.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 1/16/25.
//

import UIKit
import CoreBluetooth

/// 블루투스와 관련된 일을 전담하는 글로벌 시리얼 핸들러입니다.
//var serial : BluetoothSerial!

enum BluetoothMode: String {
    case advertisingMode = "advertisingMode"
    case scanningMode = "scanningMode"
}

protocol BluetoothSerialDelegate: AnyObject {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?)
    func serialDidConnectPeripheral(peripheral: CBPeripheral)
}

extension BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {}
}

/// 블루투스 통신을 담당할 시리얼을 클래스로 선언합니다. CoreBluetooth를 사용하기 위한 프로토콜을 추가해야합니다.
final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Properties
    
    static let shared = BluetoothSerial()
    
    static let tempUUID = "02DEA36D-2B26-484F-A1E8-FD85FC8C2658"
    
    var delegate: BluetoothSerialDelegate?
    
    var centralManager: CBCentralManager!
    
    var peripheralManager: CBPeripheralManager!
    
    var currentMode: BluetoothMode!
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻 (커스텀함)
    var serviceUUID = CBUUID(string: tempUUID)
//    var serviceUUID = CBUUID(string: "FFE0")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var characteristicUUID = CBUUID(string : "FFE1")
    
    // MARK: - Functions
    
    /// serial을 초기화할 떄 호출하여야합니다. 시리얼은 nil될 수 없기 때문에 항상 초기화후 사용해야 합니다.
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        peripheralManager.add(CBMutableService(type: serviceUUID, primary: true))
        self.currentMode = .scanningMode
    }
    
    func setBluetoothModeAndStart(to mode: BluetoothMode) {
        switch mode {
        case .advertisingMode:
            centralManager.stopScan()
            currentMode = .advertisingMode
            self.startAdvertising()
        case .scanningMode:
            peripheralManager.stopAdvertising()
            currentMode = .scanningMode
            startScan()
        }
        print("[BluetoothSerialManager] Switched mode to \(currentMode.rawValue)")
    }
    
    /// 기기 검색 시작, 연결이 가능한 모든 주변기기를 serviceUUID를 통해 검색
    func startScan() {
        if !centralManager.isScanning {
            print("=== [BluetoothSerialManager] startScan ===")
            print(">> state: \(centralManager.state)")
            guard centralManager.state == .poweredOn else { return }  // 5: poweredOn
            
            // withService가 nil 이면 모든 종류의 기기 검색 / 입력하면 특정 serviceUUID를 가진 기기만 검색 -> 특정 service만 검색하도록 함
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]  // 이미 스캔된 정보면 다시 스캔 안 하는 옵션
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: options)
            print("==========================================")
        }
        else {
            print("![Error] Central manager is already scanning!")
        }
    }
    
    /// periphalManager에 service를 추가한 후 advertise 시작하는 메소드
    func startAdvertising() {
        peripheralManager.removeAllServices()
        peripheralManager.add(CBMutableService(type: serviceUUID, primary: true))
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey : "su.yeonn_",  // TODO: 추후 사용자 아이디로 변경
            CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID]
        ])
    }

    
    // MARK: - Central, Peripheral Delegate
    
    // central 기기의 블루투스 상태가 변경될 때마다 호출
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("power Off")
        case .poweredOn:
            print("power on")
        @unknown default:
            fatalError()
        }
    }
    
    // 기기가 검색될 때마다 호출, 여기서 커스텀한 service만 찾을 수 있도록
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("=== central manager did discover peripheral ===")
        print(">> name: \(peripheral.name ?? "UNKNOWN NAME")")
        print(">> uuid: \(peripheral.identifier.uuidString)")
        print(">> advertisementData, local name: \(advertisementData[CBAdvertisementDataLocalNameKey])")
        print(">> advertisementData, service uuid: \(advertisementData[CBAdvertisementDataServiceUUIDsKey])")
        print("===============================================")
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
    }
}

// MARK: - 기기가 peripheral로서의 역할을 할 때의 메소드

extension BluetoothSerial: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("=== peripheralManagerDidUpdateState ===")
        switch peripheral.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("restting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("power Off")
        case .poweredOn:
            print("power on")
            self.peripheralManager.removeAllServices()
            self.peripheralManager.add(CBMutableService(type: serviceUUID, primary: true))
        @unknown default:
            fatalError()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        print("=== peripheralManagerDidStartAdvertising ===")
        print(peripheral.isAdvertising)
        if let error = error {
            print("![Error] \(error.localizedDescription)")
        }
        print("============================================")
    }
}
