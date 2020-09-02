import UIKit
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // アプリキル状態でURIからアプリを開いた時
        if connectionOptions.urlContexts.count == 1 {
            let content = connectionOptions.urlContexts.first!
            print(content.url)

            guard let components = URLComponents(string: content.url.absoluteString),
                let host = components.host else {
                    return
            }
            
            goToAddFamily(host: host, components: components)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // URIからの起動
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        guard let url = URLContexts.first?.url,
            let components = URLComponents(string: url.absoluteString),
            let host = components.host else {
            return
        }
        goToAddFamily(host: host, components: components)
    }
    
    // 受け取ったURIを元に家族追加画面に遷移
    func goToAddFamily(host: String, components: URLComponents) {
        if host == "login" {
           if let queryItems = components.queryItems {
                var id: String?
                for queryItem in queryItems {
                    if let value = queryItem.value {
                        // パラメータ取得
                        switch queryItem.name {
                        case "id":
                            // ログイン済みの場合のみ家族追加画面に遷移
                            Auth.auth().currentUser?.reload()
                            if (Auth.auth().currentUser?.isEmailVerified ?? false || Auth.auth().currentUser?.phoneNumber != nil) {
                                id = value
                                let addFamilyViewController: UIStoryboard = UIStoryboard(name: "AddFamilyViewController", bundle: nil)
                                let resultVC: AddFamilyViewController = addFamilyViewController.instantiateViewController(withIdentifier: "AddFamilyViewController") as! AddFamilyViewController
                                resultVC.addFamilyId = id ?? ""
                                self.window?.rootViewController = resultVC
                                self.window?.makeKeyAndVisible()
                            } else {
                                // nop
                            }
                            break
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}

