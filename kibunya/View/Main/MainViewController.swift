import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation
import FirebaseUI
import NCMB

class MainViewController: UIViewController, UITableViewDelegate {
    
    //ストレージサーバのURLを取得
    let storage = Functions.getStorageURL()
    // タブ定義
    var tabBarView: TabBarView!
    // 表示中の年月日
    @IBOutlet weak var dateText: UILabel!
    // 表示中の年月日変数
    var displayedDate: Date = Date()
    // 気分リスト定義
    @IBOutlet weak var kibunList: UITableView!
    var kibuns: [Kibuns] = [Kibuns]()
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // まだ家族が誰も日記を書いてない時のラベル
    @IBOutlet weak var emptyKibunLabel: UILabel!
    // 自分のユーザーID
    var myUserId: String? = ""
    // テーブル描画中フラグ
    var isDrawingTable: Bool = false
    // 端末内に保存している自分のプロフィール画像
    var myProfileIcon: UIImage? = nil
    // カレンダーに渡す日記を書いた日にち配列
    var writtenDate: [String]?
    // 背景色を付ける用のView
    @IBOutlet weak var backgroundView: UIView!
    // カレンダーモーダルを開くボタン
    @IBAction func openCalendarButton(_ sender: Any) {
        let storyboard: UIStoryboard = UIStoryboard(name: "KibunCalendarModalViewController", bundle: nil)
        let kibunCalendarModalViewController = storyboard.instantiateViewController(withIdentifier: "calendarModal") as! KibunCalendarModalViewController
        kibunCalendarModalViewController.writtenDate = self.writtenDate
        kibunCalendarModalViewController.selectedDate = displayedDate
        self.present(kibunCalendarModalViewController, animated: false, completion: nil)
    }
    // １日戻るボタン
    @IBOutlet weak var backDateButton: UIButton!
    @IBAction func backDateButton(_ sender: Any) {
        kibuns.removeAll()
        displayedDate = displayedDate.addingTimeInterval(-60 * 60 * 24)
        showKibuns(date: displayedDate)
        dateText.text = Functions.getDateWithDayOfTheWeek(date: displayedDate)
        nextDateButton.isEnabled = true
        nextDateButton.setImage(UIImage(named: "arrow_right_on"), for: .normal)
    }
    // １日進むボタン
    @IBOutlet weak var nextDateButton: UIButton!
    @IBAction func nextDateButton(_ sender: Any) {
        kibuns.removeAll()
        displayedDate = displayedDate.addingTimeInterval(60 * 60 * 24)
        showKibuns(date: displayedDate)
        dateText.text = Functions.getDateWithDayOfTheWeek(date: displayedDate)
        if (Functions.isToday(date: displayedDate)) {
            nextDateButton.isEnabled = false
            nextDateButton.setImage(UIImage(named: "arrow_right_off"), for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 日付の表示実行
        dateText.text = Functions.getDateWithDayOfTheWeek(date: displayedDate)
        // 日付けが今日なら進むボタンをDisabledにする
        if (Functions.isToday(date: displayedDate)) {
            nextDateButton.isEnabled = false
            nextDateButton.setImage(UIImage(named: "arrow_right_off"), for: .normal)
        }
        
        Auth.auth().currentUser?.reload()
        // 自分のユーザーIDを取得
        myUserId = Auth.auth().currentUser?.uid
        setDeviceTokenWithFamilyDocumentId()
        
        // アプリがフォアグラウンドになった時のオブザーバー登録
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.viewWillEnterForeground(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // 端末内に保存してるプロフィール画像があれば読み込む
        if (UserDefaults.standard.cachedProfileIconKey != nil) {
            myProfileIcon = Functions.loadImageFromPath(path: Functions.fileInDocumentsDirectory(filename: "profileIcon"))
        }
        
        // 気分一覧を表示
        kibunList.dataSource = self
        kibunList.delegate = self
        kibunList.register(UINib(nibName: "KibunTableViewCell", bundle: nil), forCellReuseIdentifier: "KibunTableViewCell")
        showKibuns(date: displayedDate)
        
        //installationの取得と表示
        getInstallation()
        
        // アプリアイコンの通知バッジ削除
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    override func loadView() {
        super.loadView()
        
        kibunList.backgroundColor = UIColor(red: 255/255, green: 246/255, blue: 238/255, alpha: 1)
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self

        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - Constants.TAB_BUTTON_HEIGHT, width: self.view.bounds.width, height: Constants.TAB_BUTTON_HEIGHT)
        tabBarView.diaryButton.setBackgroundImage(UIImage(named: "tab_image0_on"), for: .normal)
    }
    
    // フォアグラウンドに来た時の処理を記載
    @objc func viewWillEnterForeground(_ notification: Notification?) {
        if (self.isViewLoaded && self.view.window != nil && !isDrawingTable && Functions.isToday(date: displayedDate)) {
            dateText.text = Functions.getDateWithDayOfTheWeek(date: displayedDate)
            kibuns.removeAll()
            showKibuns(date: displayedDate)
            
            // アプリアイコンの通知バッジ削除
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    // 気分リストを設定
    func showKibuns(date: Date) {
        startIndicator()
        isDrawingTable = true
        // まず自分および家族登録してるユーザーのユーザーIDを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            self.isDrawingTable = false
            self.dismissIndicator()
            return
        }
        var familiesArray: [String] = []
        defaultStore.collection("families").whereField("user_id", arrayContains: userId).getDocuments() { (querySnapshot, err) in
            if let err = err {
                self.emptyKibunLabel.text = "読み込みエラーです"
                self.emptyKibunLabel.isHidden = false
                self.isDrawingTable = false
                self.dismissIndicator()
                print(err)
            } else {
                self.writtenDate = []   // カレンダーに渡す日にち配列初期化
                if (querySnapshot?.documents.count == 0) {  // 家族登録してる人が一人もいない
                    // 表示対象のデータを取得（指定の日付け）
                    self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: userId).whereField("date", isEqualTo: Functions.getDate(timeStamp: Timestamp(date: date))).getDocuments() { (snaps, error)  in
                        if let error = error {
                            self.isDrawingTable = false
                            self.dismissIndicator()
                            fatalError("\(error)")
                        }
                        // カレンダーに渡すデータ生成
                        self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: userId).getDocuments() { (datas, error) in
                            if (datas == nil) {
                                return
                            }
                            for data in datas!.documents {
                                self.writtenDate?.append(data.data()["date"] as! String)
                            }
                        }
                        if (snaps?.count == 0) {    // まだ今日の日記を書いてない
                            self.kibunList.isHidden = true
                            self.emptyKibunLabel.text = "誰も日記を書いてません"
                            self.emptyKibunLabel.isHidden = false
                            self.isDrawingTable = false
                            self.dismissIndicator()
                            return
                        }
                        guard let snaps = snaps else { return }
                        self.kibuns += snaps.documents.map {document in
                             let data = Kibuns(document: document)
                             return data
                         }
                        self.kibuns.sort()
                        DispatchQueue.main.async {
                            self.kibunList.reloadData()
                        }
                        self.isDrawingTable = false
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
                        self.startIndicator()
                        self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: id).whereField("date", isEqualTo: Functions.getDate(timeStamp: Timestamp(date: date))).getDocuments() { (snaps, error)  in
                            if let error = error {
                                fatalError("\(error)")
                            }
                            // カレンダーに渡すデータ生成
                            self.defaultStore.collection("kibuns").whereField("user_id", isEqualTo: id).getDocuments() { (datas, error) in
                                if (datas == nil) {
                                    return
                                }
                                for data in datas!.documents {
                                    self.writtenDate?.append(data.data()["date"] as! String)
                                }
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
                                DispatchQueue.main.async {
                                    self.kibunList.reloadData()
                                }
                            }
                            self.isDrawingTable = false
                            self.dismissIndicator()
                        }
                    }
                }
            }
        }
    }
    
    // 以下PUSH通知送信関連の処理
    func getInstallation() {
        //installationの生成
        let installation = NCMBInstallation.currentInstallation
        //ローカルのinstallationをfetchして更新
        installation.fetchInBackground(callback: { result in
            switch result {
                case .success:
                    print("取得成功:\(installation)")
                case let .failure(error):
                    print(error)
            }
        })
    }
    
    // 自分のdeviceTokenと家族ドキュメントIDの紐付け
    func setDeviceTokenWithFamilyDocumentId() {
        defaultStore.collection("families").whereField("user_id", arrayContainsAny: [myUserId!]).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else if (querySnapshot?.documents.count == 0) {
                return
            } else {
                guard let familyDocumentId = querySnapshot?.documents[0].documentID else {
                    return
                }
                Functions.setFamilyIdWithDeviceToken(familyDocumentId: familyDocumentId)
            }
        }
    }
}

extension MainViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
    }
    
    // セルがタップされた時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルの選択を解除
        tableView.deselectRow(at: indexPath, animated: false)
        let kibunDetailViewController = UIStoryboard(name: "KibunDetailViewController", bundle: nil).instantiateViewController(withIdentifier: "KibunDetailViewController") as! KibunDetailViewController
        kibunDetailViewController.diaryId = kibuns[indexPath.row].documentId!
        kibunDetailViewController.userId = kibuns[indexPath.row].user_id!
        kibunDetailViewController.time = kibuns[indexPath.row].time
        kibunDetailViewController.userName = kibuns[indexPath.row].name
        kibunDetailViewController.text = kibuns[indexPath.row].text
        kibunDetailViewController.kibun = kibuns[indexPath.row].kibun
        kibunDetailViewController.date = displayedDate
        kibunDetailViewController.imageUrl = kibuns[indexPath.row].image ?? ""
        kibunDetailViewController.modalPresentationStyle = .fullScreen
        self.present(kibunDetailViewController, animated: false, completion: nil)
    }
    
    // セルの中身を設定するデータソース
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KibunTableViewCell", for: indexPath ) as! KibunTableViewCell
        let imageRef = storage.child("profileIcon").child("\(kibuns[indexPath.row].user_id!).jpg")
        cell.userIcon.image = nil
        if (myProfileIcon != nil && kibuns[indexPath.row].user_id == myUserId) {
            cell.userIcon.image = myProfileIcon
        } else {
            cell.userIcon.sd_setImage(with: imageRef, placeholderImage: UIImage(named: "no_image"))
        }
        cell.userIcon.layer.cornerRadius = 15
        cell.clipsToBounds = true
        cell.userIcon.setNeedsLayout()
        if (kibuns[indexPath.row].image != nil && kibuns[indexPath.row].image != "") {
            cell.isExistImage.image = UIImage(named: "diary_image_icon")
            cell.isExistImage.isHidden = false
        } else {
            cell.isExistImage.isHidden = true
        }
        cell.isExistImage.setNeedsLayout()
        cell.setCell(kibuns: self.kibuns[indexPath.row])
        return cell
    }
    
    // セルの個数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kibuns.count
    }
    
    // セルの高さを指定する
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 124
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
        let imageRef = self.storage.child("diary").child("\(self.kibuns[indexPath.row].documentId!).jpg")
        imageRef.delete { error in
            if error != nil {
                print("Uh-oh, an error occurred!")
            } else {
                print("delete success!!")
            }
        }
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
