import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let TODO = ["牛乳を買う", "掃除をする", "アプリ開発の勉強をする"]
    var tabBarView: TabBarView!
    
    // セルの個数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TODO.count
    }
    
    // セルの高さを指定する
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = TODO[indexPath.row]
        return cell
    }
                                                                                                                                        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        print(Auth.auth().currentUser?.displayName ?? "名無し")
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

