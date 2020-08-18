import UIKit
import Foundation
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    // Eメール入力ボックス
    @IBOutlet weak var mailTextBox: UITextField!
    
    // パスワード入力ボックス
    @IBOutlet weak var passwordTextBox: UITextField!
    
    // ログインボタンタップ
    @IBAction func loginButton(_ sender: Any) {
        let email = mailTextBox.text ?? ""
        let password = passwordTextBox.text ?? ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let user = result?.user {
                // サインイン後の画面へ
            }
            self.showErrorIfNeeded(error)
        }
    }
    
    // 新規登録画面へボタンタップ
    @IBAction func signUpButton(_ sender: Any) {
        let signUpViewController = UIStoryboard(name: "SignUpViewController", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as UIViewController
        signUpViewController.modalPresentationStyle = .fullScreen
        self.present(signUpViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error) // エラーメッセージを取得
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func errorMessage(of error: Error) -> String {
        var message = "エラーが発生しました"
        guard let errcd = AuthErrorCode(rawValue: (error as NSError).code) else {
            return message
        }
        
        switch errcd {
        case .networkError: message = "ネットワークに接続できません"
        case .userNotFound: message = "ユーザが見つかりません"
        case .invalidEmail: message = "不正なメールアドレスです"
        case .emailAlreadyInUse: message = "このメールアドレスは既に使われています"
        case .wrongPassword: message = "入力した認証情報でサインインできません"
        case .userDisabled: message = "このアカウントは無効です"
        case .weakPassword: message = "パスワードが脆弱すぎます"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
}
