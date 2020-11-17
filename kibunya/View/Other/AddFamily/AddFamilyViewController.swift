import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Accounts

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
    // 招待から起動した際に追加家族IDを入れる変数
    var addFamilyId: String = ""
    
    // 戻るボタンタップ
    @IBAction func backButton(_ sender: Any) {
        let otherViewController = UIStoryboard(name: "OtherViewController", bundle: nil).instantiateViewController(withIdentifier: "OtherViewController") as! OtherViewController
        otherViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(otherViewController, animated: false, completion: nil)
    }
    //  ユーザーIDを入力するテキストボックス
    @IBOutlet weak var userIdInputTextBox: UITextField!
    
    // ユーザー検索ボタン
    @IBOutlet weak var searchUserButton: UIButton!
    @IBAction func searchUserButton(_ sender: Any) {
        searchUser()
    }
    
    // ユーザーID検索処理
    func searchUser() {
        if (userIdInputTextBox.text == myUserId) {
            userNameLabel.text = "自分のユーザーIDです"
            userNameLabel.isHidden = false
            Functions.updateButtonEnabled(button: addFamilyButton, enabled: false)
            return
        }
        startIndicator()
        
        let ref = defaultStore.collection("users").document(userIdInputTextBox.text ?? "")
        ref.getDocument{ (document, error) in
            if let data = document?.data() {
                self.familyUserName = data["name"] as? String
                self.userNameLabel.text = self.familyUserName
                self.userNameLabel.isHidden = false
                self.familyUserId = self.userIdInputTextBox.text ?? ""
                Functions.updateButtonEnabled(button: self.addFamilyButton, enabled: true)
            } else {
                self.userNameLabel.text = "該当するユーザーがいません"
                self.userNameLabel.isHidden = false
                Functions.updateButtonEnabled(button: self.addFamilyButton, enabled: false)
            }
            self.dismissIndicator()
        }
        addedFamily.isHidden = true
    }
    
    // 検索したユーザー名を表示するラベル
    @IBOutlet weak var userNameLabel: UILabel!
    
    // 家族に追加するボタン
    @IBOutlet weak var addFamilyButton: UIButton!
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
                    let ref: DocumentReference? = nil
                    self.defaultStore.collection("families").addDocument(data: [
                        "user_id": [userId, self.familyUserId]
                    ]) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            self.addedFamilyLabel.text = self.familyUserName
                            self.userNameLabel.isHidden = true
                            self.addedFamily.isHidden = true
                            
                            // 自分のdeviceTokenと家族ドキュメントIDの紐付け
                            if (ref != nil) {
                                Functions.setFamilyIdWithDeviceToken(familyDocumentId: ref!.documentID)
                            }
                        }
                    }
                } else {    // 自分か相手のユーザーIDがいずれかの家族に追加済みの場合
                    if (querySnapshot?.documents.count == 2) { // 自分と相手がそれぞれ別の家族データを持ってる場合（家族のマージ）
                        // 1つ目の家族のドキュメントIDを取得
                        guard let familyDocumentId1 = querySnapshot?.documents[0].documentID else {
                            return
                        }
                        // 1つ目の家族全員のユーザーIDを配列で取得
                        guard let familyArray1 = querySnapshot?.documents[0].data()["user_id"] else {
                            return
                        }
                        // 2つ目の家族のドキュメントIDを取得
                        guard let familyDocumentId2 = querySnapshot?.documents[1].documentID else {
                            return
                        }

                        // 1つ目の家族の全ユーザーIDを2つ目の家族に追加
                        for id in familyArray1 as! [String?] {
                            self.defaultStore.collection("families").document(familyDocumentId2).updateData(["user_id": FieldValue.arrayUnion([id!])]) { err in
                                if let err = err {
                                    // エラー
                                    print("Error writing document: \(err)")
                                } else {
                                    // 成功
                                    print("Document successfully written!")
                                    self.addedFamilyLabel.text = self.familyUserName
                                    self.addFamilyInfo.text = "と家族になりました！"
                                    self.addedFamily.isHidden = false
                                    self.userNameLabel.isHidden = true
                                    
                                    // 自分のdeviceTokenと家族ドキュメントIDの紐付け
                                    Functions.setFamilyIdWithDeviceToken(familyDocumentId: familyDocumentId2)
                                }
                            }
                        }
                        
                        // 1つ目の家族を削除
                        self.defaultStore.collection("families").document(familyDocumentId1).delete(){ err in
                            if let err = err{
                                print("Error removing document: \(err)")
                            }else{
                                print("Document successfully removed!")
                            }
                        }
                    } else {
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
                                        self.addFamilyInfo.text = "と家族になりました！"
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
                                       self.addFamilyInfo.text = "と家族になりました！"
                                       self.addedFamily.isHidden = false
                                    
                                    // 自分のdeviceTokenと家族ドキュメントIDの紐付け
                                    Functions.setFamilyIdWithDeviceToken(familyDocumentId: document.documentID)
                                   }
                               }
                           }
                        }
                   }
                }
            }
            self.dismissIndicator()
        }
    }
    
    let userName: String = Auth.auth().currentUser?.displayName ?? ""
    
    // 追加した家族名を表示する領域
    @IBOutlet weak var addedFamily: UIView!
    @IBOutlet weak var addedFamilyLabel: UILabel!
    @IBOutlet weak var addFamilyInfo: UILabel!
    @IBOutlet weak var myUserIdTextBox: UITextField!

    // 自分のIDを共有
    @IBOutlet weak var otherShareButton: UIButton!
    @IBAction func otherShareButton(_ sender: Any) {
        let shareName: String = userName
        let shareId: String = myUserId
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: ["家族の交換日記アプリ「家族ダイアリー」\n" + shareName + "からの招待です。\n\nkazokuDiary://login?id=" + shareId + "\n\nアプリをダウンロード\nhttps://apps.apple.com/us/app/id1528947553"], applicationActivities: nil)
        
        // 使用しないアクティビティタイプ
        let excludedActivityTypes = [
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.airDrop,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.markupAsPDF,
            UIActivity.ActivityType.openInIBooks,
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.postToVimeo
        ]
        
        activityVC.excludedActivityTypes = excludedActivityTypes

        // UIActivityViewControllerを表示
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addedFamily.isHidden = true
        
        Auth.auth().currentUser?.reload()
        guard let myUserId = Auth.auth().currentUser?.uid else {
            return
        }
        myUserIdTextBox.text = myUserId
        self.myUserId = myUserId
        
        userIdInputTextBox.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        // 招待から起動した場合、追加するIDを入力済みにして検索実行
        if (!addFamilyId.isEmpty) {
            userIdInputTextBox.text = addFamilyId
            searchUser()
        }
        
        userIdInputTextBox.delegate = self
        myUserIdTextBox.delegate = self
        
        self.setupToHideKeyboardOnTapOnView()
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self
        
        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - Constants.TAB_BUTTON_HEIGHT, width: self.view.bounds.width, height: Constants.TAB_BUTTON_HEIGHT)
        tabBarView.otherButton.setBackgroundImage(UIImage(named: "tab_image2_on"), for: .normal)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする。
        if(view.isFirstResponder) {
            userIdInputTextBox.resignFirstResponder()
            myUserIdTextBox.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (userIdInputTextBox.text!.count > 0) {
            Functions.updateButtonEnabled(button: searchUserButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: searchUserButton, enabled: false)
        }
    }
}
