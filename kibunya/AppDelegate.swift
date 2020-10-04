import UIKit
import Firebase
import FirebaseAuth
import FirebaseCore
import UserNotifications
import FirebaseMessaging
import NCMB
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // ニフクラのAPIキーの設定
    let applicationkey = "23cdc4478a47767b5f49bcfa80b33aa8087f5d4ad96192a457489ccac91a4721"
    let clientkey      = "645eb370a2b644caae9d229392ac3b654593913d2f996040c8751027453f0fa2"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        // SDKの初期化
        NCMB.initialize(applicationKey: applicationkey, clientKey: clientkey)
        
        // Register notification
        registerForPushNotifications()
        
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //端末情報を扱うNCMBInstallationのインスタンスを作成
        let installation : NCMBInstallation = NCMBInstallation.currentInstallation
        installation.setDeviceTokenFromData(data: deviceToken)
        installation.saveInBackground(callback: { result in
            switch result {
            case .success:
                //端末情報の登録が成功した場合の処理
                UserDefaults.standard.devicetokenKey = deviceToken
                break
            case let .failure(error):
                //端末情報の登録が失敗した場合の処理
                let errorCode = (error as! NCMBApiError).errorCode;
                if (errorCode == NCMBApiErrorCode.duplication) {
                    //失敗した原因がdeviceTokenの重複だった場合
                    self.updateExistInstallation(installation: installation, deviceToken: deviceToken)
                } else {
                    //deviceTokenの重複以外のエラーが返ってきた場合
                }
                return
            }
        })
     }

     func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
         // 1. Print out error if PNs registration not successful
         print("Failed to register for remote notifications with error: \(error)")
     }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // Print message ID.
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Print message ID.
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
       let userInfo = notification.request.content.userInfo

       if let messageID = userInfo["gcm.message_id"] {
           print("Message ID: \(messageID)")
       }

       print(userInfo)

       completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
       let userInfo = response.notification.request.content.userInfo
       if let messageID = userInfo["gcm.message_id"] {
           print("Message ID: \(messageID)")
       }

       print(userInfo)

       completionHandler()
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current() // 1
            .requestAuthorization(options: [.alert, .sound, .badge]) { // 2
                granted, error in
                print("Permission granted: \(granted)") // 3
                guard granted else { return }
                self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    //deviceTokenの重複で端末情報の登録に失敗した場合に上書き処理を行う
    func updateExistInstallation(installation: NCMBInstallation, deviceToken: Data) -> Void {
        var installationQuery : NCMBQuery<NCMBInstallation> = NCMBInstallation.query
        installationQuery.where(field: "deviceToken", equalTo: installation.deviceToken!)
        installationQuery.findInBackground(callback: {results in
            switch results {
            case let .success(data):
                //上書き保存する
                let searchDevice:NCMBInstallation = data.first!
                installation.objectId = searchDevice.objectId
                installation.saveInBackground(callback: { result in
                    switch result {
                    case .success:
                        //端末情報更新に成功したときの処理
                        UserDefaults.standard.devicetokenKey = deviceToken
                        break
                    case .failure:
                        //端末情報更新に失敗したときの処理
                        break
                    }
                })
            case .failure:
                //端末情報検索に失敗した場合の処理
                break
            }
        })
    }
}
