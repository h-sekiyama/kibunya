import UIKit
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    // ログイン画面へ遷移する
    @IBAction func loginButton(_ sender: Any) {
        let loginViewController = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as UIViewController
        loginViewController.modalPresentationStyle = .fullScreen
        self.present(loginViewController, animated: false, completion: nil)
    }
    
    @IBAction private func didTapSignUpButton() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let name = nameTextField.text ?? ""
        
        signUp(email: email, password: password, name: name)
        startIndicator()
    }

    private func signUp(email: String, password: String, name: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let user = result?.user {
                self.updateDisplayName(name, of: user)
            }
            self.showError(error)
        }
    }

    private func updateDisplayName(_ name: String, of user: User) {
        let request = user.createProfileChangeRequest()
        request.displayName = name
        request.commitChanges() { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.sendEmailVerification(to: user)
            } else {
                self.showError(error)
            }
        }
    }

    private func sendEmailVerification(to user: User) {
        user.sendEmailVerification() { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.showSignUpCompletion()
            } else {
                self.showError(error)
            }
        }
    }
    
    private func showSignUpCompletion() {
        self.dismissIndicator()
        
        // この時点でユーザー情報をサーバDBに登録
        Auth.auth().currentUser?.reload()
        defaultStore.collection("users").document(Auth.auth().currentUser?.uid ?? "").setData([
            "name": Auth.auth().currentUser?.displayName as Any
        ])
        
        // 確認メール送信完了画面に遷移
        let mailSendCompleteViewController = UIStoryboard(name: "MailSendCompleteViewController", bundle: nil).instantiateViewController(withIdentifier: "MailSendCompleteViewController") as UIViewController
        mailSendCompleteViewController.modalPresentationStyle = .fullScreen
        self.present(mailSendCompleteViewController, animated: true, completion: nil)
    }

    private func showError(_ errorOrNil: Error?) {
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
        default: break
        }
        return message
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Auth.auth().currentUser?.reload()
        // メール認証済みなら即メイン画面を表示
        if (Auth.auth().currentUser?.isEmailVerified ?? false) {
            let mailSendCompleteViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
            mailSendCompleteViewController.modalPresentationStyle = .fullScreen
            self.present(mailSendCompleteViewController, animated: true, completion: nil)
        }
    }
}
