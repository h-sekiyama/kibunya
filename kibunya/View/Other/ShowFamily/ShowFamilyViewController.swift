import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

class ShowFamilyViewController: UIViewController, UITableViewDelegate {
    // タブ定義
    var tabBarView: TabBarView!
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
    // 家族が一人もいない時のラベル
    @IBOutlet weak var emptyFamilyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        // 自分のユーザーID取得
        Auth.auth().currentUser?.reload()
        guard let myUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
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
                } else {
                    self.familyArray = querySnapshot?.documents[0].data()["user_id"] as! [String]
                    for id in self.familyArray {
                        let ref = self.defaultStore.collection("users").document(id)
                        if (!UIViewController.isShowIndicator) {
                            self.startIndicator()
                        }
                        ref.getDocument{ (document, error) in
                            if let name = document.flatMap({ data in
                                return  data["name"]
                            }) {
                                self.familyNameArray.append(name as! String)
                            }
                            self.tableView.reloadData()
                            if (UIViewController.isShowIndicator) {
                                self.dismissIndicator()
                            }
                        }
                    }
                }
                self.dismissIndicator()
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self

        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY - 80, width: self.view.bounds.width, height: 80)
    }
}

extension ShowFamilyViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = familyNameArray[indexPath.row]
        return cell
    }
    
    // セルの個数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return familyNameArray.count
    }
    
    // セルの高さを指定する
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
