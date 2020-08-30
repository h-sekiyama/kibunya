import UIKit
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
    // 名前入力ボックス
    @IBOutlet private weak var nameTextField: UITextField!
    // メールアドレス入力フィールド
    @IBOutlet private weak var emailTextField: UITextField!
    // メールログインパスワード入力フィールド
    @IBOutlet private weak var passwordTextField: UITextField!
    // 電話番号入力フィールド
    @IBOutlet weak var telNoTextField: UITextField!
    
    // ログイン画面へ遷移する
    @IBAction func loginButton(_ sender: Any) {
        let loginViewController = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as UIViewController
        loginViewController.modalPresentationStyle = .fullScreen
        self.present(loginViewController, animated: false, completion: nil)
    }
    
    // メールアドレスで登録するボタン
    @IBOutlet weak var signUpButton: UIButton!
    @IBAction private func didTapSignUpButton() {
        let name = nameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        signUp(email: email, password: password, name: name)
        startIndicator()
    }
    
    // メールアドレスで登録処理
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
        self.present(mailSendCompleteViewController, animated: false, completion: nil)
    }

    private func showError(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
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
    
    // 電話番号で登録するボタン
    @IBOutlet weak var telNoSignUpButton: UIButton!
    @IBAction func didTapTelNoSignUpButton(_ sender: Any) {
        startIndicator()
        let telNo = telNoTextField.text ?? ""   // 形式は「+1 80 1234 5678」の様な形である必要がある
        Auth.auth().currentUser?.reload()
        // 入力した電話番号が端末に紐づく番号と一致した場合は即メイン画面を表示
        if (Auth.auth().currentUser?.phoneNumber == telNo) {
            
            login()
        } else {
            
            PhoneAuthProvider.provider().verifyPhoneNumber(telNo, uiDelegate: nil) { (verificationID, error) in
                if let error = error {
                    self.showMessagePrompt(message: "ErrorDescription \(error.localizedDescription)")
                    self.dismissIndicator()
                    return
                }
                // 確認IDをアプリ側で保持しておく
                if let verificationID = verificationID {
                    print("verificationID \(verificationID)")
                    UserDefaults.standard.authVerificationID = verificationID
                }
                
                // SMS認証コード送信完了画面に遷移
                let sMSSendCompleteViewController = UIStoryboard(name: "SMSSendCompleteViewController", bundle: nil).instantiateViewController(withIdentifier: "SMSSendCompleteViewController") as UIViewController
                sMSSendCompleteViewController.modalPresentationStyle = .fullScreen
                self.present(sMSSendCompleteViewController, animated: false, completion: nil)
                self.dismissIndicator()
            }
        }
    }
    
    // メイン画面に遷移
    func login() {
        let mailSendCompleteViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
        mailSendCompleteViewController.modalPresentationStyle = .fullScreen
        self.present(mailSendCompleteViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        emailTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        passwordTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        telNoTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Auth.auth().currentUser?.reload()
        // メール認証済みなら即メイン画面を表示
        if (Auth.auth().currentUser?.isEmailVerified ?? false) {
            login()
        }
        // ログイン中の電話番号がUserDefaultにある場合は即メイン画面を表示
        if (Auth.auth().currentUser?.phoneNumber != nil) {
            login()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする
        if(nameTextField.isFirstResponder) {
            nameTextField.resignFirstResponder()
        }
        if(emailTextField.isFirstResponder) {
            emailTextField.resignFirstResponder()
        }
        if(passwordTextField.isFirstResponder) {
            passwordTextField.resignFirstResponder()
        }
        if(telNoTextField.isFirstResponder) {
            telNoTextField.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (nameTextField.text!.count > 0 && emailTextField.text!.count > 0 && passwordTextField.text!.count > 0) {
            signUpButton.isEnabled = true
        } else {
            signUpButton.isEnabled = false
        }
        
        if (telNoTextField.text!.count == 13) {
            telNoSignUpButton.isEnabled = true
        } else {
            telNoSignUpButton.isEnabled = false
        }
        
        // 入力文字数制限をつける（電話番号テキストフィールド）
        guard let telNoText = telNoTextField.text else { return }
        telNoTextField.text = String(telNoText.prefix(13))
    }
}

extension UIViewController {
    // アラートダイアログを表示する処理
    func showMessagePrompt(message: String) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        (navigationController ?? self)?.present(alertController, animated: true, completion: nil)
    }
}

