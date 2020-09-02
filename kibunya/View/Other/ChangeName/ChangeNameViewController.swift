import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

class ChangeNameViewController: UIViewController, UITextFieldDelegate {
    // タブ定義
    var tabBarView: TabBarView!
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // 名前入力テキストボックス
    @IBOutlet weak var nameTextBox: UITextField!
    // 名前変更ボタン
    @IBOutlet weak var updateNameButton: UIButton!
    @IBAction func updateName(_ sender: Any) {
        startIndicator()
        Auth.auth().currentUser?.reload()
        // 自分のユーザーIDを取得
        guard let myUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = nameTextBox.text
        changeRequest?.commitChanges { (error) in
            if (error != nil) {
                self.nameChangeResultView.isHidden = true
                return
            }
            self.nameChangeResultView.isHidden = false
            self.afterName.text = self.nameTextBox.text
            
            self.defaultStore.collection("users").document(myUserId).updateData(["name": self.nameTextBox.text!]) { err in
                if let err  = err {
                    print("Error update document: \(err)")
                }else{
                    print("Document successfully update")
                }
            }
            
            self.dismissIndicator()
        }
    }
    
    // 名前変更完了後に表示するView
    @IBOutlet weak var nameChangeResultView: UIView!
    // 変更後の名前ラベル
    @IBOutlet weak var afterName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定済みの名前をテキストフィールドに表示
        Auth.auth().currentUser?.reload()
        guard let name = Auth.auth().currentUser?.displayName else {
            return
        }
        nameTextBox.text = name
        
        nameTextBox.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self

        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - 80, width: self.view.bounds.width, height: 80)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする。
        if(nameTextBox.isFirstResponder) {
            nameTextBox.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (nameTextBox.text!.count > 0) {
            updateNameButton.isEnabled = true
        } else {
            updateNameButton.isEnabled = false
        }
    }
}
