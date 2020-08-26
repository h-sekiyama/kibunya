import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

class MainViewController: UIViewController, UITableViewDelegate {
    
    // タブ定義
    var tabBarView: TabBarView!
    // 今日の日付text
    @IBOutlet weak var dateText: UILabel!
    // 気分リスト定義
    @IBOutlet weak var kibunList: UITableView!
    var kibuns: [Kibuns] = [Kibuns]()
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // まだ家族が誰も日記を書いてない時のラベル
    @IBOutlet weak var emptyKibunLabel: UILabel!
    // 自分のユーザーID
    var myUserId: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 日付の表示実行
        dispDate()
        
        // 気分一覧を表示
        kibunList.dataSource = self
        kibunList.delegate = self
        kibunList.register(UINib(nibName: "KibunTableViewCell", bundle: nil), forCellReuseIdentifier: "KibunTableViewCell")
        self.showKibuns()
        
        Auth.auth().currentUser?.reload()
        // 自分のユーザーIDを取得
        myUserId = Auth.auth().currentUser?.uid
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
        startIndicator()
        // まず自分および家族登録してるユーザーのユーザーIDを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        var familiesArray: [String] = []
        defaultStore.collection("families").whereField("user_id", arrayContains: userId).getDocuments() { (querySnapshot, err) in
            if let err = err {
                self.emptyKibunLabel.text = "読み込みエラーです"
                self.emptyKibunLabel.isHidden = false
                self.dismissIndicator()
                print(err)
            } else {
                if (querySnapshot?.documents.count == 0) {  // 家族登録してる人が一人もいない
                    // 表示対象のデータを取得（今日の日付け）
                    self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: userId).whereField("date", isEqualTo: Functions.getDate(timeStamp: Timestamp(date: Date()))).getDocuments() { (snaps, error)  in
                        if let error = error {
                            fatalError("\(error)")
                        }
                        if (snaps?.count == 0) {    // まだ今日の日記を書いてない
                            self.kibunList.isHidden = true
                            self.emptyKibunLabel.text = "まだ今日の日記を書いてません"
                            self.emptyKibunLabel.isHidden = false
                            return
                        }
                        guard let snaps = snaps else { return }
                        self.kibuns += snaps.documents.map {document in
                             let data = Kibuns(document: document)
                             return data
                         }
                        self.kibuns.sort()
                        self.kibunList.reloadData()
                        self.dismissIndicator()
                     }
                } else {    // 家族が一人以上いる
                    for document in querySnapshot!.documents {
                        _ = document.data()["user_id"].map {ids in
                            (ids as! [String]).map {id in
                                familiesArray.append(id)
                            }
                        }
                    }
                    
                    // 表示対象のデータを取得（今日の日付け＆家族設定している人）
                    _ = familiesArray.enumerated().map { index, id in
                        if (!UIViewController.isShowIndicator) {
                            self.startIndicator()
                        }
                        self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: id).whereField("date", isEqualTo: Functions.getDate(timeStamp: Timestamp(date: Date()))).getDocuments() { (snaps, error)  in
                            if let error = error {
                                fatalError("\(error)")
                            }
                            guard let snaps = snaps else { return }
                            self.kibuns += snaps.documents.map {document in
                                let data = Kibuns(document: document)
                                return data
                            }
                            if (self.kibuns.count == 0) {    // まだ家族の誰も今日の日記を書いてない
                                self.kibunList.isHidden = true
                                self.emptyKibunLabel.isHidden = false
                            } else {
                                self.kibunList.isHidden = false
                                self.emptyKibunLabel.isHidden = true
                                self.kibuns.sort()
                                self.kibunList.reloadData()
                            }
                            if (UIViewController.isShowIndicator) {
                                self.dismissIndicator()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension MainViewController: UITableViewDataSource {
    
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
    
    // セルの編集許可（自分の投稿のみ）
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if (self.kibuns[indexPath.row].user_id! == myUserId) {
            return true
        } else {
            return false
        }
    }

    // スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            defaultStore.collection("kibuns").document(self.kibuns[indexPath.row].documentId!).delete() { err in
                if let err = err{
                    print("Error removing document: \(err)")
                }else{
                    print("Document successfully removed!")
                    self.kibuns.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                }
            }
        }
    }
}
