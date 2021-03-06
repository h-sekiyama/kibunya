import UIKit
import Foundation
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    // Eメール入力ボックス
    @IBOutlet weak var mailTextBox: UITextField!
    // パスワード入力ボックス
    @IBOutlet weak var passwordTextBox: UITextField!
    // メール認証未実施ラベル
    @IBOutlet weak var notYetMailAuth: UILabel!
    // ログインボタン
    @IBOutlet weak var loginButton: UIButton!
    // ログインボタンタップ
    @IBAction func loginButton(_ sender: Any) {
        startIndicator()
        let email = mailTextBox.text ?? ""
        let password = passwordTextBox.text ?? ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if (result?.user) != nil {
                Auth.auth().currentUser?.reload()
                // メール認証済みの場合のみログイン
                if (Auth.auth().currentUser?.isEmailVerified ?? false) {
                    // 気分リスト画面に遷移
                    let mainViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
                    mainViewController.modalPresentationStyle = .fullScreen
                    self.present(mainViewController, animated: false, completion: nil)
                } else {
                    self.notYetMailAuth.isHidden = false
                }
                self.dismissIndicator()
            }
            self.showErrorIfNeeded(error)
            self.dismissIndicator()
        }
    }
    
    // パスワードリセット画面へボタンタップ
    @IBAction func forgetPasswordButton(_ sender: Any) {
        let forgetPasswordViewController = UIStoryboard(name: "ForgetPasswordViewController", bundle: nil).instantiateViewController(withIdentifier: "ForgetPasswordViewController") as UIViewController
        forgetPasswordViewController.modalPresentationStyle = .fullScreen
        self.present(forgetPasswordViewController, animated: false, completion: nil)
    }
    // 新規登録画面へボタンタップ
    @IBAction func signUpButton(_ sender: Any) {
        let signUpViewController = UIStoryboard(name: "SignUpViewController", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as UIViewController
        signUpViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(signUpViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailTextBox.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        passwordTextBox.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする
        if(mailTextBox.isFirstResponder) {
            mailTextBox.resignFirstResponder()
        }
        if(passwordTextBox.isFirstResponder) {
            passwordTextBox.resignFirstResponder()
        }
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
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (mailTextBox.text!.count > 0 && passwordTextBox.text!.count > 0) {
            Functions.updateButtonEnabled(button: loginButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: loginButton, enabled: false)
        }
    }
}
