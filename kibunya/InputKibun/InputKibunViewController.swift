import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class InputKibunViewController: UIViewController, UITextFieldDelegate {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
    // 気分情報を入れる変数
    var kibunStatus: Int? = nil
    
    // 今日あった出来事を入力するテキストボックス
    @IBOutlet weak var kibunTextBox: UITextField!
    
    // 最高ボタンタップ
    @IBAction func kibunButton0(_ sender: Any) {
        kibunStatus = 0
    }
    // 良いボタンタップ
    @IBAction func kibunButton1(_ sender: Any) {
        kibunStatus = 1
    }
    // 普通ボタンタップ
    @IBAction func kibunButton2(_ sender: Any) {
        kibunStatus = 2
    }
    // 悪いボタンタップ
    @IBAction func kibunButton3(_ sender: Any) {
        kibunStatus = 3
    }
    // 最悪ボタンタップ
    @IBAction func kibunButton4(_ sender: Any) {
        kibunStatus = 4
    }
    // 送信ボタンタップ
    @IBAction func sendButton(_ sender: Any) {
        startIndicator()
        updateData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        if(kibunTextBox.isFirstResponder) {
            kibunTextBox.resignFirstResponder()
        }
    }
    
    @IBOutlet weak var sendKibunCompleteLabel: UILabel!
    
    // サーバDBをアップデートする処理
    func updateData() {
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        guard let userName = Auth.auth().currentUser?.displayName else {
            return
        }
        if (kibunStatus == nil) {
            return
        }

        defaultStore.collection("kibuns").addDocument(data: [
            "kibun": kibunStatus!,
            "date": Functions.today(),
            "text": kibunTextBox.text ?? "",
            "name": userName,
            "user_id": userId
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.sendKibunCompleteLabel.isHidden = true
            } else {
                self.sendKibunCompleteLabel.isHidden = false
            }
            self.dismissIndicator()
        }
    }
}
