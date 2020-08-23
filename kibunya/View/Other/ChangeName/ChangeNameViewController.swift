import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

class ChangeNameViewController: UIViewController, UITextFieldDelegate {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    // 名前入力テキストボックス
    @IBOutlet weak var nameTextBox: UITextField!
    
    // 名前変更ボタン
    @IBAction func updateName(_ sender: Any) {
        startIndicator()
        Auth.auth().currentUser?.reload()
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = nameTextBox.text
        changeRequest?.commitChanges { (error) in
            if (error != nil) {
                self.nameChangeResultView.isHidden = true
                return
            }
            self.nameChangeResultView.isHidden = false
            self.afterName.text = self.nameTextBox.text
            
            // TODO: usersコレクションの更新処理も追加
            
            self.dismissIndicator()
        }
    }
    
    // 名前変更完了後に表示するView
    @IBOutlet weak var nameChangeResultView: UIView!
    
    // 変更後の名前ラベル
    @IBOutlet weak var afterName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().currentUser?.reload()
        guard let name = Auth.auth().currentUser?.displayName else {
            return
        }
        nameTextBox.text = name
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
}
