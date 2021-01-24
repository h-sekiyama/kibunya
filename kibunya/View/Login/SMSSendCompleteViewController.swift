import Foundation
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SMSSendCompleteViewController: UIViewController {
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
    // 認証コード入力テキストフィールド
    @IBOutlet weak var verificationIdTextField: UITextField!
    // 名前入力テキストフィールド
    @IBOutlet weak var nameTextField: UITextField!
    // 登録ボタン
    @IBOutlet weak var signUpButton: UIButton!
    @IBAction func didSignUp(_ sender: Any) {
        startIndicator()
        guard let verificationID = UserDefaults.standard.authVerificationID else {
            self.showMessagePrompt(message: "NoVerificationID")
            return
        }
        let verificationCode = verificationIdTextField.text!
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        // TODO: 既に登録済みの電話番号の場合は弾く処理追加
        
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                self.showMessagePrompt(message: "ErrorDescription \(error.localizedDescription)")
                self.dismissIndicator()
                return
            }
            if authResult != nil {
                // displayNameが空の場合更新
                if (Auth.auth().currentUser?.displayName == nil) {
                    // この時点でユーザー情報をサーバDBに登録
                    Auth.auth().currentUser?.reload()
                    self.defaultStore.collection("users").document(Auth.auth().currentUser?.uid ?? "").setData([
                        "name": self.nameTextField.text ?? "名無しの猫ちゃん"
                    ])
                    
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = self.nameTextField.text!
                        changeRequest?.commitChanges { error in
                            if let error = error {
                                self.showMessagePrompt(message: "ErrorDescription \(error.localizedDescription)")
                                self.dismissIndicator()
                                return
                            }
                        }
                }
                // メイン画面に遷移
                let mailSendCompleteViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
                mailSendCompleteViewController.modalPresentationStyle = .fullScreen
                self.present(mailSendCompleteViewController, animated: false, completion: nil)
                self.dismissIndicator()
            }
        }
    }
    
    // 新規登録画面に戻る
    @IBAction func toSignUpButton(_ sender: Any) {
        let signUpViewController = UIStoryboard(name: "SignUpViewController", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as UIViewController
        signUpViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(signUpViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verificationIdTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする
        if(nameTextField.isFirstResponder) {
            nameTextField.resignFirstResponder()
        }
        if(verificationIdTextField.isFirstResponder) {
            verificationIdTextField.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (verificationIdTextField.text!.count == 6 && verificationIdTextField.text!.count > 0) {
            Functions.updateButtonEnabled(button: signUpButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: signUpButton, enabled: false)
        }
        
        // 入力文字数制限をつける（認証コードテキストフィールド）
        guard let verificationIdText = verificationIdTextField.text else { return }
        verificationIdTextField.text = String(verificationIdText.prefix(6))
    }
}
