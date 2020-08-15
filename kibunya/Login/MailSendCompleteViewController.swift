import UIKit
import Foundation
import Firebase
import FirebaseAuth

class MailSendCompleteViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().currentUser?.reload()
        print(Auth.auth().currentUser?.isEmailVerified ?? false ? "登録済み！" : "未登録！")
    }
}
