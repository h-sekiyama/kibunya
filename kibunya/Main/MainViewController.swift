import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    // 今日の日付text
    @IBOutlet weak var dateText: UILabel!
    
    // 気分リスト定義
    @IBOutlet weak var kibunList: UITableView!
    var kibuns: [Kibuns] = [Kibuns]()
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
                                                                                                                        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 日付の表示実行
        dispDate()
        
        // 気分一覧を表示
        kibunList.dataSource = self
        kibunList.delegate = self
        kibunList.register(UINib(nibName: "KibunTableViewCell", bundle: nil), forCellReuseIdentifier: "KibunTableViewCell")
        self.showKibuns()
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
    
    // 日付の表示
    func dispDate() {
        let date = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateStr = formatter.string(from: date as Date)
        formatter.locale = NSLocale(localeIdentifier: "ja_JP") as Locale?
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEE", options: 0, locale:  Locale.current)
        let weekStr = formatter.string(from:  date as Date)
        dateText.text = dateStr + " (" + weekStr + ")"
    }
    
    // 気分リストを設定
    func showKibuns() {
        // まず自分および家族登録してるユーザーのユーザーIDを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        var familiesArray: [String] = []
        defaultStore.collection("families").whereField("user_id", arrayContains: userId).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    _ = document.data()["user_id"].map {ids in
                        (ids as! [String]).map {id in
                            familiesArray.append(id)
                        }
                    }
                }
                
                // 表示対象のデータを取得（今日の日付け＆家族設定している人）
                _ = familiesArray.map { id in
                    self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: id).whereField("date", isEqualTo: Functions.today()).getDocuments() { (snaps, error)  in
                        if let error = error {
                            fatalError("\(error)")
                        }
                        guard let snaps = snaps else { return }
                        self.kibuns += snaps.documents.map {document in
                            let data = Kibuns(document: document)
                            return data
                        }
                        self.kibunList.reloadData()
                    }
                }
            }
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
}
