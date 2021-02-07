import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseUI
import NCMB

class KibunDetailViewController:  UIViewController, UITableViewDelegate, UITableViewDataSource {

    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    //ストレージサーバのURLを取得
    let storage = Functions.getStorageURL()
    // 日記のドキュメントID
    var diaryId: String = ""
    // 投稿者のユーザーID
    var userId: String = ""
    // 投稿日時
    var time: Timestamp? = nil
    // 投稿日時（Date型）
    var date: Date = Date()
    // 投稿者名
    var userName: String? = ""
    // 投稿文
    var text: String? = ""
    // 気分
    var kibun: Int? = 0
    // 画像URL
    var imageUrl: String = ""
    // タブ定義
    var tabBarView: TabBarView!
    
    // 年月日時間
    @IBOutlet weak var timeLabel: UILabel!
    // ユーザーの名前
    @IBOutlet weak var userNameLabel: UILabel!
    // 投稿画像
    @IBOutlet weak var diaryImage: UIImageView!
    // 日記の投稿時間
    @IBOutlet weak var diaryTime: UILabel!
    // 日記本文
    @IBOutlet weak var textLabel: UITextView!
    // 日記本文の高さ
    @IBOutlet weak var textLabelHeight: NSLayoutConstraint!
    // ユーザーアイコン
    @IBOutlet weak var profileIcon: UIImageView!
    // 気分アイコン画像
    @IBOutlet weak var kibunImage: UIImageView!
    // 戻るボタン
    @IBAction func backButton(_ sender: Any) {
        let mainViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        mainViewController.displayedDate = date
        mainViewController.modalPresentationStyle = .fullScreen
        // 遷移アニメーション定義
        Functions.presentAnimation(view: view)
        self.present(mainViewController, animated: false, completion: nil)
    }
    // スクロールエリア
    @IBOutlet weak var scrollView: UIScrollView!
    // コメント一覧
    @IBOutlet weak var comments: UITableView!
    var commentData: [Comments] = [Comments]()
    // コメントエリアの高さ
    @IBOutlet weak var commentViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 上部の投稿年月日表示
        timeLabel.text = "\(Functions.getDateWithDayOfTheWeek(date: date))"
        // 投稿者名表示
        userNameLabel.text = userName!
        // 日記本文表示
        textLabel.text = text!
        // 投稿者プロフィールアイコン表示
        if (imageUrl != "") {
        diaryImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
            diaryImage.sd_setImage(with: URL(string: imageUrl))
        } else {
            diaryImage.isHidden = true
        }
        // 日記の投稿時間表示
        diaryTime.text  = Functions.getTime(timeStamp: time!)
        
        // 本文タップ時にキーボードを出さない様にする
        textLabel.isUserInteractionEnabled = true
        textLabel.isEditable = false
        
        // 気分アイコン設定
        self.kibunImage.image = UIImage(named: "kibunIcon\(kibun ?? 0)")
        
        // プロフィール画像設定
        let placeholderImage = UIImage(named: "no_image")
        profileIcon.sd_setImage(with: self.storage.child("profileIcon").child("\(userId).jpg"), maxImageSize: 10000000, placeholderImage: placeholderImage, options: .refreshCached) { _, _, _, _ in
            // nop
        }
        
        // 日記本文の背景設定
        textLabel.backgroundColor = UIColor(red: 255/255, green: 246/255, blue: 238/255, alpha: 1)
        
        if (UserDefaults.standard.billingProMode ?? false) { // 課金ユーザー
            // 画像の保存
            diaryImage.isUserInteractionEnabled = true
            diaryImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.saveImage(_:))))
        }
        
        // 日記本文の高さを取得
        let textHeight = textLabel.sizeThatFits(CGSize(width: textLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height + 42
        textLabel.heightAnchor.constraint(equalToConstant: textHeight).isActive = true
        
        // 日記本文の（本来の）高さを設定
        textLabelHeight.constant = textHeight
        
        comments.dataSource = self
        comments.delegate = self
        comments.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "CommentTableViewCell")
        showComment()
        
        comments.rowHeight = UITableView.automaticDimension
        comments.estimatedRowHeight = 40
        
        commentTextBox.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                if commentTextBox.convert(commentTextBox.frame, to: self.view).origin.y > (self.view.frame.height - keyboardSize.height) {
                    self.view.frame.origin.y -= keyboardSize.height
                }
            } else {
                if commentTextBox.convert(commentTextBox.frame, to: self.view).origin.y > (self.view.frame.height - keyboardSize.height) {
                    let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                    self.view.frame.origin.y -= suggestionHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
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
        tabBarView.diaryButton.setBackgroundImage(UIImage(named: "tab_image0_on"), for: .normal)
    }
    
    // コメントセルの数を指定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentData.count
    }
    
    // コメントセルの中身を入れる
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath ) as! CommentTableViewCell
        let imageRef = storage.child("profileIcon").child("\(commentData[indexPath.row].user_id!).jpg")
        cell.userIcon.sd_setImage(with: imageRef, placeholderImage: UIImage(named: "no_image"))
        cell.name.text = commentData[indexPath.row].name
        cell.commentText.text = commentData[indexPath.row].text
        cell.time.text = Functions.getDateTime(timeStamp: commentData[indexPath.row].time!)
        return cell
    }
    
    // コメントを表示
    func showComment() {
        defaultStore.collection("comments").whereField("diary_id", isEqualTo: diaryId).getDocuments() { (snaps, error)  in
            if let err = error {
                print(err)
            } else {
                self.commentData.removeAll()
                self.commentViewHeight.constant = 0
                guard let snaps = snaps else { return }
                self.commentData += snaps.documents.map {document in
                    let data = Comments(document: document)
                    return data
                }
                self.commentData.sort()
                DispatchQueue.main.async {
                    self.comments.reloadData()
                    self.comments.layoutIfNeeded()
                    self.comments.updateConstraints()
                    // コメントエリアの高さを設定
                    self.commentViewHeight.constant = self.comments.contentSize.height + (21 * CGFloat(self.commentData.count))
                }
            }
        }
    }
    
    // コメント入力ボックス
    @IBOutlet weak var commentTextBox: UITextView!
    // コメント送信ボタン
    @IBOutlet weak var sendCommentButton: UIButton!
    // コメント送信アクション
    @IBAction func sendComment(_ sender: Any) {
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        guard let commentUserName = Auth.auth().currentUser?.displayName else {
            return
        }
        
        sendComment(userId: userId, commentUserName: commentUserName)
    }
    
    // コメント送信処理
    func sendComment(userId: String, commentUserName: String) {
        self.startIndicator()
        defaultStore.collection("comments").document().setData([
            "text": commentTextBox.text ?? "",
            "name": commentUserName,
            "user_id": userId,
            "time": Date(),
            "diary_id": diaryId,
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                self.commentData.removeAll()
                self.comments.reloadData()
                self.showComment()
                
                // PUSH通知を送る
                self.sendUpdateCommentPush(commentUserName: commentUserName, myUserId: userId)
            }
            self.dismissIndicator()
            self.commentTextBox.text = ""
            Functions.updateButtonEnabled(button: self.sendCommentButton, enabled: false)
            self.commentTextBox.endEditing(true)
        }
    }
    
    // 家族にのみコメント更新通知のPUSHを送る処理
    private func sendUpdateCommentPush(commentUserName: String, myUserId: String) {
        // 自分が所属する家族が存在すればPUSH送信
        defaultStore.collection("families").whereField("user_id", arrayContainsAny: [myUserId]).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if (querySnapshot?.documents.count == 0) {
                    return
                }
                guard let familyDocumentId = querySnapshot?.documents[0].documentID else {
                    return
                }
                // プッシュ通知オブジェクトの作成
                let push : NCMBPush = NCMBPush()
                push.sound = "default"
                push.badgeIncrementFlag = false
                push.contentAvailable = false
                push.searchCondition?.where(field: "channels", toMatchPattern: familyDocumentId)
                if (UserDefaults.standard.devicetokenKey != nil) {
                    let deviceTokenString = UserDefaults.standard.devicetokenKey!.map { String(format: "%.2hhx", $0) }.joined()
                    push.searchCondition?.where(field: "deviceToken", notEqualTo: deviceTokenString)
                }
                // メッセージの設定
                push.message = "\(commentUserName)が\(self.userName!)の日記にコメントしました"
                // 即時配信を設定する
                push.setImmediateDelivery()

                // プッシュ通知を配信登録する
                push.sendInBackground(callback: { result in
                    switch result {
                    case .success:
                        print("登録に成功しました。プッシュID: \(push.objectId!)")
                    case let .failure(error):
                        print("登録に失敗しました: \(error)")
                        return;
                    }
                })
            }
        }
    }
    
    @objc func saveImage(_ sender: UITapGestureRecognizer) {

        //タップしたUIImageViewを取得
        let targetImageView = sender.view! as! UIImageView
        // その中の UIImage を取得
        let targetImage = targetImageView.image!
        //保存するか否かのアラート
        let alertController = UIAlertController(title: "保存", message: "この画像を保存しますか？", preferredStyle: .alert)
        //OK
        let okAction = UIAlertAction(title: "OK", style: .default) { (ok) in
            //ここでフォトライブラリに画像を保存
            UIImageWriteToSavedPhotosAlbum(targetImage, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        //CANCEL
        let cancelAction = UIAlertAction(title: "しない", style: .default) { (cancel) in
            alertController.dismiss(animated: true, completion: nil)
        }
        //OKとCANCELを表示追加し、アラートを表示
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 保存結果をアラートで表示
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {

        var title = "保存完了"
        var message = "カメラロールに保存しました"

        if error != nil {
            title = "エラー"
            message = "保存に失敗しました"
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }
}

// コメント入力監視
extension KibunDetailViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView){
        if (commentTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendCommentButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: sendCommentButton, enabled: false)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (commentTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendCommentButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: sendCommentButton, enabled: false)
        }
        return true
    }
}
