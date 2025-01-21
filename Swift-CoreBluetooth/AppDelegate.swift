//
//  AppDelegate.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 9/30/24.
//

import UIKit
import UserNotifications
import BackgroundTasks

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
        
        registerBackgroundTasks()
        
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

    /// 앱의 launch sequence가 끝나기 전에 Background Task를 Scheduler에 "등록"해야 합니다.
    /// Info.plist에 등록한 키 값으로 등록해야 합니다.
    private func registerBackgroundTasks() {
        print("[AppDelegate] Background Task 등록!")
        // RefreshTask
        // 1. Refresh Task 등록
        let taskIdentifier = ["NearbyPochak"]
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier[0], using: nil, launchHandler: { task in
            // 2. 실제로 수행할 Background 동작 구현
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
            print("do backgroundtask")
        })
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        let operationQueue = OperationQueue()
        
        scheduleBackgroundTask()  // 다음 백그라운드 작업 예약
        
        print("[AppDelegate] Background task 수행 중")
        
        let operation = BluetoothRefreshOperation()
        
        // Background Task가 갑자기 종료되거나 TimeOut될 때를 대비
        task.expirationHandler = {
//            task.setTaskCompleted(success: false)  // task가 완료되었음을 알려줌 (백그라운드 자원 이용 stop)
            operation.cancel()
        }
        
        operation.completionBlock = {
            // 백그라운드 작업 스케줄러에게 작업 완료됨 알리기
            task.setTaskCompleted(success: !operation.isCancelled)
            BluetoothSerial.shared.centralManager.stopScan()
            print("[AppDelegate] Background task completed with Success: \(!operation.isCancelled)")
        }
        
        // TODO: background 태스크 수행 - central mode on 하기
        
        // 실행 대기열에 추가 -> 비동기로 실행
        operationQueue.addOperation(operation)
        
    }
    
    func scheduleBackgroundTask() {
        let task = BGAppRefreshTaskRequest(identifier: "NearbyPochak")
        task.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60)  // 최소 120초 TODO: 변경
        
        do {
            print("[AppDelegate] Background Task submitted!")
            try BGTaskScheduler.shared.submit(task)  // Background Task 등록!!
        } catch {
            print("[!] Error - Could not schedule app refresh")
        }
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
