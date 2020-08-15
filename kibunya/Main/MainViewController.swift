import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // タブ定義
    var tabBarView: TabBarView!
    
    // 気分リスト定義
    @IBOutlet weak var kibunList: UITableView!
    var kibuns: [Kibuns] = [Kibuns]()
                                                                                                                                        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        print(Auth.auth().currentUser?.displayName ?? "名無し")
        
        kibunList.dataSource = self
        kibunList.delegate = self
        kibunList.register(UINib(nibName: "TestCell", bundle: nil), forCellReuseIdentifier: "TestCell")
        self.setKibuns()
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        
        // タブの表示位置を調整
        NSLayoutConstraint.activate([
            tabBarView.tab.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // 気分リストを設定
    func setKibuns() {
        kibuns = [
            Kibuns(name: "みっちゃん", user_id: 0, kibun: 0, text: "今日は勉強がはかどる", date: Date()),
            Kibuns(name: "ゆき", user_id: 1, kibun: 1, text: "アンジュノに会いたい", date: Date())
        ]
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath ) as! TestCell
        cell.setCell(kibuns: kibuns[indexPath.row])
        return cell
    }
    
    // セルの個数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kibuns.count
    }
    
    // セルの高さを指定する
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    // サーバDBをアップデートする処理
    func updateData() {
        let defaultStore: Firestore! = Firestore.firestore()
        
        defaultStore.collection("kibuns").document("yucco").setData([
            "kibun": 3,
            "date": Date()
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
}

