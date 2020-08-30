import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class InputKibunViewController: UIViewController {
    // タブ定義
    var tabBarView: TabBarView!
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // 気分情報を入れる変数
    var kibunStatus: Int? = nil
    // 今日あった出来事を入力するテキストボックス
    @IBOutlet weak var kibunTextBox: UITextView!
    
    // 最高ボタンタップ
    @IBAction func kibunButton0(_ sender: Any) {
        kibunStatus = 0
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
        }
    }
    // 良いボタンタップ
    @IBAction func kibunButton1(_ sender: Any) {
        kibunStatus = 1
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
        }
    }
    // 普通ボタンタップ
    @IBAction func kibunButton2(_ sender: Any) {
        kibunStatus = 2
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
        }
    }
    // 悪いボタンタップ
    @IBAction func kibunButton3(_ sender: Any) {
        kibunStatus = 3
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
        }
    }
    // 最悪ボタンタップ
    @IBAction func kibunButton4(_ sender: Any) {
        kibunStatus = 4
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
        }
    }
    // 送信ボタン
    @IBOutlet weak var sendButton: UIButton!
    // 送信ボタンタップ
    @IBAction func sendButton(_ sender: Any) {
        if (kibunTextBox.text.count == 0) {
            sendKibunCompleteLabel.text = "気分が未入力です"
            sendKibunCompleteLabel.isHidden = false
        } else {
            startIndicator()
            updateData()
        }
    }
    // 残り入力可能文字数
    @IBOutlet weak var remainingTextCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // テキストボックス入力監視
        kibunTextBox.delegate = self
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
        // キーボードを非表示にする
        if(kibunTextBox.isFirstResponder) {
            kibunTextBox.resignFirstResponder()
        }
    }
    
    // 気分送信完了ラベル
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

        // ドキュメントIDを事前に設定する
        let documentId = defaultStore.collection("kibuns").document().documentID
        defaultStore.collection("kibuns").document(documentId).setData([
            "kibun": kibunStatus!,
            "date": Functions.today(),
            "text": kibunTextBox.text ?? "",
            "name": userName,
            "user_id": userId,
            "time": Date(),
            "documentId": documentId
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.sendKibunCompleteLabel.isHidden = true
            } else {
                self.sendKibunCompleteLabel.text = "今日の気分を送信しました！"
                self.sendKibunCompleteLabel.isHidden = false
            }
            self.dismissIndicator()
            self.kibunTextBox.text = ""
            self.sendButton.isEnabled = false
        }
    }
}

extension InputKibunViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView){
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
        // 入力を反映させたテキストを取得する
        let resultText: String = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        self.remainingTextCountLabel.text = String(140 - resultText.count)
        if resultText.count < 140 {
            return true
        }
        return false
    }
}
