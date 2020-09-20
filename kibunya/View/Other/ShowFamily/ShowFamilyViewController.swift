import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation
import FirebaseUI

class ShowFamilyViewController: UIViewController, UITableViewDelegate {
    // タブ定義
    var tabBarView: TabBarView!
    //ストレージサーバのURLを取得
    let storage = Storage.storage().reference(forURL: "gs://kibunya-app.appspot.com")
    // 家族リスト
    @IBOutlet weak var tableView: UITableView!
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // 自分のユーザーID
    var myUserId: String = ""
    // 家族のユーザーID配列
    private var familyArray: [String] = []
    // 家族名の配列
    private var familyNameArray: [String] = []
    // 家族のプロフィールアイコンURLの配列
    private var familyProfileIconArray: [StorageReference] = []
    // 家族を識別するID（ドキュメント名）
    private var familyId: String = ""
    // 端末内に保存している自分のプロフィール画像
    var myProfileIcon: UIImage? = nil
    // 家族が一人もいない時のラベル
    @IBOutlet weak var emptyFamilyLabel: UILabel!
    // 戻るボタンタップ
    @IBAction func backButton(_ sender: Any) {
        let otherViewController = UIStoryboard(name: "OtherViewController", bundle: nil).instantiateViewController(withIdentifier: "OtherViewController") as! OtherViewController
        otherViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(otherViewController, animated: false, completion: nil)
    }
    // 家出するボタン
    @IBOutlet weak var runawayButton: UIButton!
    @IBAction func runawayButton(_ sender: Any) {
        let dialog = UIAlertController(title: "家出しますか？", message: "家出すると家族が一人もいなくなります", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "家出する", style: .default,
            handler: { action in
                let newFamilyArray = self.familyArray.filter {
                    $0 != self.myUserId
                }
                self.defaultStore.collection("families").document(self.familyId).updateData(["user_id" : newFamilyArray]){ err in
                    if let err  = err {
                        print("Error update document: \(err)")
                    }else{
                        print("Document successfully update")
                    }
                    self.updateFamilyList()
                }
            }))
        dialog.addAction(UIAlertAction(title: "しない", style: .cancel, handler: nil))
        // 生成したダイアログを実際に表示します
        self.present(dialog, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        // 自分のユーザーID取得
        Auth.auth().currentUser?.reload()
        myUserId = Auth.auth().currentUser?.uid ?? ""
        updateFamilyList()
        
        // 端末内に保存してるプロフィール画像があれば読み込む
        if (UserDefaults.standard.cachedProfileIconKey != nil) {
            myProfileIcon = Functions.loadImageFromPath(path: Functions.fileInDocumentsDirectory(filename: "profileIcon"))
        }
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
    
    func updateFamilyList() {
        startIndicator()
        defaultStore.collection("families").whereField("user_id", arrayContains: myUserId).getDocuments() { (querySnapshot, err) in
            if let err = err {
                self.emptyFamilyLabel.text = "読み込みエラーです"
                self.tableView.isHidden = true
                self.emptyFamilyLabel.isHidden = false
                self.dismissIndicator()
                print(err)
            } else {
                if (querySnapshot?.documents.count == 0) {  // 自分か相手のユーザーIDがまだ家族登録されていない場合
                    self.emptyFamilyLabel.text = "まだ家族が一人もいません"
                    self.tableView.isHidden = true
                    self.emptyFamilyLabel.isHidden = false
                    self.runawayButton.isHidden = true
                } else {
                    self.familyId = querySnapshot?.documents[0].documentID ?? ""
                    self.familyArray = querySnapshot?.documents[0].data()["user_id"] as! [String]
                    for id in self.familyArray {
                        let ref = self.defaultStore.collection("users").document(id)
                        self.startIndicator()
                        ref.getDocument{ (document, error) in
                            if let name = document.flatMap({ data in
                                return  data["name"]
                            }) {
                                self.familyNameArray.append(name as! String)
                                self.familyProfileIconArray.append(self.storage.child("profileIcon").child("\(id).jpg"))
                            }
                            self.tableView.reloadData()
                            self.dismissIndicator()
                        }
                    }
                    self.runawayButton.isEnabled = true
                }
                self.dismissIndicator()
            }
        }
    }
}

extension ShowFamilyViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
    }
    
    // セルがタップされた時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルの選択を解除
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let profileIcon = cell.viewWithTag(1) as! UIImageView
        profileIcon.sd_setImage(with: familyProfileIconArray[indexPath.row], placeholderImage: UIImage(named: "no_image"))
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = familyNameArray[indexPath.row]
        return cell
    }
    
    // セルの個数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return familyNameArray.count
    }
    
    // セルの高さを指定する
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
