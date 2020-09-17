import UIKit
import Foundation
import Firebase
import FirebaseAuth

class MailSendCompleteViewController: UIViewController {
    
    @IBAction func loginButton(_ sender: Any) {
        let loginViewController = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as UIViewController
        loginViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(loginViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().currentUser?.reload()
        print(Auth.auth().currentUser?.isEmailVerified ?? false ? "登録済み！" : "未登録！")
    }
}
