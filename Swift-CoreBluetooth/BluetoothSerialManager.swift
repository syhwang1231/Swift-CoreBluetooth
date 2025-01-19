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
    func serialDidReceiveMessage(message: String)
}

extension BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {}
    func serialDidReceiveMessage(message: String) {}
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
    
    /// 현재 연결 시도 중인 주변기기
    var pendingPeripheral: CBPeripheral?
    
    var connectedPeripheral: CBPeripheral?
    
    /// 데이터를 주변기기에 보내기 위한 characteristic을 저장
    weak var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻 (커스텀함)
    var serviceUUID = CBUUID(string: tempUUID)
//    var serviceUUID = CBUUID(string: "FFE0")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var characteristicUUID = CBUUID(string : "FFE1")
    
    /// 블루투스 기기와 성공적으로 연결되었고, 통신이 가능한 상태라면 true를 반환합니다.
    var bluetoothIsReady: Bool  {
        get {
            return centralManager.state == .poweredOn &&
            //connectedPeripheral != nil &&
            writeCharacteristic != nil
        }
    }
    
    // MARK: - Functions
    
    /// serial을 초기화할 떄 호출하여야합니다. 시리얼은 nil될 수 없기 때문에 항상 초기화후 사용해야 합니다.
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        peripheralManager.add(CBMutableService(type: serviceUUID, primary: true))
        self.currentMode = .scanningMode
    }
    
    func setBluetoothMode(to mode: BluetoothMode) {
        switch mode {
        case .advertisingMode:
            stopScan()
            currentMode = .advertisingMode
            self.addServicesWithData("")
        case .scanningMode:
            peripheralManager.stopAdvertising()
            startScan()
            currentMode = .scanningMode
        }
        print("switched mode to.. \(currentMode.rawValue)")
    }
    
    /// 기기 검색을 시작합니다. 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾아냅니다.
    func startScan() {
        print("=== start scan ===")
        print("state: \(centralManager.state)")
        guard centralManager.state == .poweredOn else { return }  // 5: poweredOn
        
        // withService가 nil 이면 모든 종류의 기기 검색 / 입력하면 특정 serviceUUID를 가진 기기만 검색 -> 특정 service만 검색하도록 함
        print("scanning..")
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]  // 이미 스캔된 정보면 다시 스캔 안 하는 옵션
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: options)
    }
    
    /// 기기 검색 중단
    func stopScan() {
        centralManager.stopScan()
    }
    
    /// 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도합니다.
    func connectToPeripheral(_ peripheral : CBPeripheral) {
        // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    /// String 형식으로 데이터를 주변기기에 전송합니다.
    func sendMessageToDevice(_ message: String) {
        print("=== sendMessageToDevice() ===")
        print("bluetoothIsReady: \(bluetoothIsReady)")
        guard bluetoothIsReady else { return }
        
        // String을 utf8 형식의 데이터로 변환하여 전송합니다.
        if let data = message.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }
    }
    
    /// 데이터 Array를 Byte형식으로 주변기기에 전송합니다.
    func sendBytesToDevice(_ bytes: [UInt8]) {
        guard bluetoothIsReady else { return }
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    /// 데이터를 주변기기에 전송합니다.
    func sendDataToDevice(_ data: Data) {
        guard bluetoothIsReady else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    /// peripheral에 커스텀한 service를 추가, service가 추가되면 delegate에서 감지 후 peripheralManager didAdd가 호출됨
    func addServicesWithData(_ data: String) {
        print("=== addServicesWithData ===")
        let valueData = data.data(using: .utf8)
        
//        // 1. Create instance of CBMutableCharcateristic
//        let myChar1 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()),
//                                              properties: [.notify, .write, .read],
//                                              value: nil,
//                                              permissions: [.readable, .writeable])
//        let myChar2 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()),
//                                              properties: [.read],
//                                              value: valueData,  // central 기기가 읽게 되는 데이터 값
//                                              permissions: [.readable])
        
        // 2. Create instance of CBMutableService
        let myService = CBMutableService(type: serviceUUID, primary: true)
        
        // 3. Add characteristics to the service
//        myService.characteristics = [myChar1, myChar2]
        
        // 4. Add service to peripheralManager
        peripheralManager.add(myService)
        
        // 5. Start advertising
//        startAdvertising()
        print("==========================")
    }
    
    func startAdvertising() {
        print("=== Advertising Data ===")
        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey : "su.yeonn_",
            CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID]
        ])
        print("Started Advertising")
    }

    
    // MARK: - Central, Peripheral Delegate
    
    // central 기기의 블루투스 상태가 변경될 때마다 호출
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
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
        @unknown default:
            fatalError()
        }
        pendingPeripheral = nil
        connectedPeripheral = nil
    }
    
    // 기기가 검색될 때마다 호출
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("=== central manager did discover peripheral ===")
        print(">> name: \(peripheral.name ?? "UNKNOWN"))")
        print(">> uuid: \(peripheral.identifier.uuidString)")
        print(">> advertisementData: \(advertisementData[CBAdvertisementDataLocalNameKey])")
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
    }
    
//    // 기기가 연결되면 호출되는 메서드입니다.
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        peripheral.delegate = self
//        pendingPeripheral = nil
//        connectedPeripheral = peripheral
//    
//        // peripheral의 Service들을 검색합니다.파라미터를 nil으로 설정하면 peripheral의 모든 service를 검색합니다.
//        peripheral.discoverServices([serviceUUID])
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
//        print("=== Disconnect Peripheral ===")
//    }
    
//    // service 검색에 성공 시 호출되는 메서드입니다.
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        for service in peripheral.services! {
//            // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 characteristic을 검색합니다.
//            peripheral.discoverCharacteristics([characteristicUUID], for: service)
//        }
//    }
    
//    // characteristic 검색에 성공 시 호출되는 메서드입니다.
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        for characteristic in service.characteristics! {
//            // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정을 완료합니다.
//            if characteristic.uuid == characteristicUUID {
//                // 해당 기기의 데이터를 구독합니다.
//                peripheral.setNotifyValue(true, for: characteristic)
//                // 데이터를 보내기 위한 characteristic을 저장합니다.
//                writeCharacteristic = characteristic
//                // 데이터를 보내는 타입을 설정합니다. 이는 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경됩니다.
//                writeType = characteristic.properties.contains(.write) ? .withResponse :  .withoutResponse
//                // 주변 기기와 연결 완료 시 동작하는 코드를 여기에 작성합니다.
//                delegate?.serialDidConnectPeripheral(peripheral: peripheral)
//            }
//        }
//    }

    // peripheral으로부터 데이터를 전송받으면 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // 전송받은 데이터가 존재하는지 확인합니다.
        let data = characteristic.value
        guard data != nil else { return }
        
        // 데이터를 String으로 변환하고, 변환된 값을 파라미터로 한 delegate함수를 호출합니다.
        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            if str == "this is pochak user:su.yeonn" {
                delegate?.serialDidReceiveMessage(message : str)
            }
        } else {
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 메서드입니다.
        // 필요한 로직을 작성하면 됩니다.
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 메서드입니다.
        // 신호 강도와 관련된 코드를 작성합니다.
        // 필요한 로직을 작성하면 됩니다.
    }
}

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
        pendingPeripheral = nil
        connectedPeripheral = nil
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        print("=== peripheralManager didAdd Service ===")
        self.peripheralManager.startAdvertising([
                CBAdvertisementDataLocalNameKey: "su.yeonn_",
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            ])
        print("=========================================")
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
