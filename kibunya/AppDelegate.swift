import UIKit
import Firebase
import FirebaseAuth
import FirebaseCore
import UserNotifications
import FirebaseMessaging
import NCMB
import UserNotifications
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // ニフクラのAPIキーの設定
    #if kibunya_dev
        // 検証環境
        let applicationkey = "362179601d478e841d36e745ba1f4516cd0bcfb5d0123a1bd5d0960dcdd3dd61"
        let clientkey      = "69c1601ca32cd5b0581bde8fda9fa3a0e69ec34a92f321fa7122aca63fe681eb"
    #else
        // 本番環境
        let applicationkey = "23cdc4478a47767b5f49bcfa80b33aa8087f5d4ad96192a457489ccac91a4721"
        let clientkey      = "645eb370a2b644caae9d229392ac3b654593913d2f996040c8751027453f0fa2"
    #endif


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
        
        // Admobの初期化
        GADMobileAds.sharedInstance().start { (status) in
            // 初期化が完了(or タイムアウト)
            debugPrint("AdMob Initialization Completed")
            for (k,v) in status.adapterStatusesByClassName {
                debugPrint("\(k) >> \(v.state.rawValue == 1 ? "Ready" : "NotReady")")
            }
        }
        
        // 課金の準備
        SKPaymentQueue.default().add(IAPManager.shared)
        
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
            case .failure(_):
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
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                granted, error in
                print("Permission granted: \(granted)")
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
