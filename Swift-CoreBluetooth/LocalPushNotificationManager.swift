//
//  LocalPushNotificationManager.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 1/20/25.
//

import UserNotifications

class LocalPushNotificationManager {
    
    static let shared = LocalPushNotificationManager()
    
    private init() { }
    
    func pushNotification(title: String, body: String, /*seconds: Double,*/ identifier: String) {
        let notificationContent = UNMutableNotificationContent()  // 내용
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = .default

        let request = UNNotificationRequest(identifier: identifier,
                                            content: notificationContent,
                                            trigger: nil)

        // 알림 등록
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[!] LocalPushNotificationManager Error: ", error)
            }
        }
    }
}
