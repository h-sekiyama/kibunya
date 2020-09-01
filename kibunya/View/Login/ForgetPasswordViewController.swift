import UIKit
import Foundation
import Firebase
import FirebaseAuth

class ForgetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    // Eメールアドレステキストフィールド
    @IBOutlet weak var mailTextField: UITextField!
    // メール送信ボタン
    @IBOutlet weak var sendMailButton: UIButton!
    @IBAction func sendMailButton(_ sender: Any) {
        startIndicator()
        let email = mailTextField.text ?? ""
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.showErrorIfNeeded(error)
                self.sendCompleteLabel.isHidden = true
            } else {
                self.dismissIndicator()
                self.sendMailButton.setTitle("再送する", for: .normal)
                self.sendCompleteLabel.isHidden = false
            }
        }
    }
    
    // ログイン画面へ遷移ボタン
    @IBAction func goToLoginButton(_ sender: Any) {
        let loginViewController = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as UIViewController
        loginViewController.modalPresentationStyle = .fullScreen
        self.present(loginViewController, animated: false, completion: nil)
    }
    
    // パスワード送信完了ラベル
    @IBOutlet weak var sendCompleteLabel: UILabel!
    
    // エラー表示
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        dismissIndicator()
        let message = errorMessage(of: error) // エラーメッセージを取得
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: false, completion: nil)

    }
    
    private func errorMessage(of error: Error) -> String {
        var message = "エラーが発生しました"
        guard let errcd = AuthErrorCode(rawValue: (error as NSError).code) else {
            return message
        }
        
        switch errcd {
        case .networkError: message = "ネットワークに接続できません"
        case .userNotFound: message = "このメールアドレスは登録されていません"
        case .invalidEmail: message = "不正なメールアドレスです"
        case .userDisabled: message = "このアカウントは無効です"
        default: break
        }
        return message
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mailTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする
        if(mailTextField.isFirstResponder) {
            mailTextField.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (mailTextField.text!.count > 0) {
            sendMailButton.isEnabled = true
        } else {
            sendMailButton.isEnabled = false
        }
    }
}
