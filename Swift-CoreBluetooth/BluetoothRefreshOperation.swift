//
//  BluetoothRefreshOperation.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 1/21/25.
//

import Foundation

class BluetoothRefreshOperation: Operation {
    
    override func main() {
        if isCancelled {
            return
        }
        
        let date = Date()
        
        BluetoothSerial.shared.setBluetoothModeAndStart(to: .scanningMode)
        
        // 작업 완료 시 로그 출력
        print("Background task executed and date saved at \(date)")
    }
}
