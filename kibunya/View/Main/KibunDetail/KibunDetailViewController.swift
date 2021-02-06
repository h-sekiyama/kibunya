import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseUI

class KibunDetailViewController:  UIViewController {
    
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
        let textHeight = textLabel.sizeThatFits(CGSize(width: textLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        textLabel.heightAnchor.constraint(equalToConstant: textHeight).isActive = true
        
        //スクロールエリアの高さを画像と本文の高さの合計に設定
        scrollView.contentSize.height = diaryImage.frame.height + textHeight
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
