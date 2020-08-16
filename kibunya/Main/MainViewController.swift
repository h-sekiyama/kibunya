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
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    

                                                                                                                                        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        print(Auth.auth().currentUser?.displayName ?? "名無し")
        
        kibunList.dataSource = self
        kibunList.delegate = self
        kibunList.register(UINib(nibName: "KibunTableViewCell", bundle: nil), forCellReuseIdentifier: "KibunTableViewCell")
        self.setKibuns()
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        
        tabBarView.owner = self
        
        // タブの表示位置を調整
        NSLayoutConstraint.activate([
            tabBarView.tab.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // 気分リストを設定
    func setKibuns() {
        defaultStore.collection("kibuns").getDocuments {(snaps, error) in
            if let error = error {
                fatalError("\(error)")
            }
            guard let snaps = snaps else { return }
            self.kibuns = snaps.documents.map {document in
                let data = Kibuns(document: document)
                return data
            }
            self.kibunList.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KibunTableViewCell", for: indexPath ) as! KibunTableViewCell
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

