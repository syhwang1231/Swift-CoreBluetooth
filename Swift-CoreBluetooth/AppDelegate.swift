//
//  AppDelegate.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 9/30/24.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound] // 필요한 알림 권한을 설정
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 알림을 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let application = UIApplication.shared
        
        // 앱이 켜져있는 상태
        if application.applicationState == .active {
            print("푸시알림 탭(앱 켜져있음)")
            if response.notification.request.identifier == "POCHAK_NEARBY" {
                guard let rootViewController = (application.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
                if let navVC = rootViewController as? UINavigationController {  // TODO: 포착 루트뷰컨에 맞게 수정하기
                    navVC.pushViewController(SecondViewController(), animated: true)
                }
            }
        }
        
        // 앱이 꺼져있는 상태
        if application.applicationState == .inactive {
            print("푸시알림 탭(앱 꺼져있음)")
            if response.notification.request.identifier == "POCHAK_NEARBY" {
                guard let rootViewController = (application.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
                if let navVC = rootViewController as? UINavigationController {  // TODO: 포착 루트뷰컨에 맞게 수정하기
                    navVC.pushViewController(SecondViewController(), animated: true)
                }
            }
            
        }
    }
    
    // Foreground(앱 켜진 상태)에서도 알림 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .banner])
    }
}
