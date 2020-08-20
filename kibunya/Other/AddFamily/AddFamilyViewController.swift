import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AddFamilyViewController: UIViewController, UITextFieldDelegate {
  
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // タブ定義
    var tabBarView: TabBarView!
    // 追加する家族のユーザーID保存変数
    var familyUserId: String = ""
    // 追加する家族の名前保存変数
    var familyUserName: String? = ""
    // 自分のユーザーID
    var myUserId: String = ""
    
    //  ユーザーIDを入力するテキストボックス
    @IBOutlet weak var userIdInputTextBox: UITextField!
    
    // ユーザー検索ボタン
    @IBAction func searchUserButton(_ sender: Any) {
        startIndicator()
        
        let ref = defaultStore.collection("users").document(userIdInputTextBox.text ?? "")
        ref.getDocument{ (document, error) in
            if let data = document?.data() {
                self.familyUserName = data["name"] as? String
                self.userNameLabel.text = self.familyUserName
                self.familyUserId = self.userIdInputTextBox.text ?? ""
            } else {
                self.userNameLabel.text = "該当するユーザーがいません"
            }
            self.dismissIndicator()
        }
        addedFamily.isHidden = true
    }
    
    // 検索したユーザー名を表示するラベル
    @IBOutlet weak var userNameLabel: UILabel!
    
    // 検索したユーザーを家族に追加
    @IBAction func addFamilyButton(_ sender: Any) {
        startIndicator()
        
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        defaultStore.collection("families").whereField("user_id", arrayContainsAny: [userId, familyUserId]).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if (querySnapshot?.documents.count == 0) {  // 自分か相手のユーザーIDがまだ家族登録されていない場合
                    self.defaultStore.collection("families").addDocument(data: [
                        "user_id": [userId, self.familyUserId]
                    ]) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            self.addedFamilyLabel.text = self.familyUserName
                            self.addedFamily.isHidden = false
                        }
                    }
                } else {    // 自分か相手のユーザーIDがいずれかの家族に追加済みの場合
                    // 相手のIDが登録済みかどうか
                    var isContainOpponentId = false
                    // 自分のIDが登録済みかどうか
                    var isContainMyId = false
                    
                    for document in querySnapshot!.documents {
                        _ = document.data()["user_id"].map {ids in
                            _ = (ids as! [String]).map {id in
                                if (id == self.familyUserId) {
                                    isContainOpponentId = true
                                }
                            }
                            _ = (ids as! [String]).map {id in
                                if (id == self.myUserId) {
                                    isContainMyId = true
                                }
                            }
                        }
                    }
                    if (isContainMyId && isContainOpponentId) { // 追加しようとした家族も自分も既にに登録済みの場合
                        self.addedFamilyLabel.text = self.familyUserName
                        self.addFamilyInfo.text = "は既に家族登録済みです"
                        self.addedFamily.isHidden = false
                    } else if (isContainMyId) { // 追加しようとした相手のみ未登録の場合
                        for document in querySnapshot!.documents {
                            self.defaultStore.collection("families").document(document.documentID).updateData(["user_id": FieldValue.arrayUnion([self.familyUserId])]) { err in
                                if let err = err {
                                    // エラー
                                    print("Error writing document: \(err)")
                                } else {
                                    // 成功
                                    print("Document successfully written!")
                                    self.addedFamilyLabel.text = self.familyUserName
                                    self.addFamilyInfo.text = "を家族に追加しました！"
                                    self.addedFamily.isHidden = false
                                }
                            }
                        }
                    } else if (isContainOpponentId) { // 自分のみ未登録の場合
                       for document in querySnapshot!.documents {
                           self.defaultStore.collection("families").document(document.documentID).updateData(["user_id": FieldValue.arrayUnion([self.myUserId])]) { err in
                               if let err = err {
                                   // エラー
                                   print("Error writing document: \(err)")
                               } else {
                                   // 成功
                                   print("Document successfully written!")
                                   self.addedFamilyLabel.text = self.familyUserName
                                   self.addFamilyInfo.text = "の家族に参加しました！"
                                   self.addedFamily.isHidden = false
                               }
                           }
                       }
                   }
                }
            }
            self.dismissIndicator()
        }
    }
    
    // 追加した家族名を表示する領域
    @IBOutlet weak var addedFamily: UIView!
    @IBOutlet weak var addedFamilyLabel: UILabel!
    @IBOutlet weak var addFamilyInfo: UILabel!
    @IBOutlet weak var myUserIdTextBox: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addedFamily.isHidden = true
        
        Auth.auth().currentUser?.reload()
        guard let myUserId = Auth.auth().currentUser?.uid else {
            return
        }
        myUserIdTextBox.text = myUserId
        self.myUserId = myUserId
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
        if(userIdInputTextBox.isFirstResponder) {
            userIdInputTextBox.resignFirstResponder()
        }
        if(myUserIdTextBox.isFirstResponder) {
            myUserIdTextBox.resignFirstResponder()
        }
    }
}
