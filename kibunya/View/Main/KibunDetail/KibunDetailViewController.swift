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
        profileIcon.sd_setImage(with: self.storage.child("profileIcon").child("\(userId).jpg"), placeholderImage: placeholderImage)
        
        // 日記本文の背景設定
        textLabel.backgroundColor = UIColor(red: 255/255, green: 246/255, blue: 238/255, alpha: 1)
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
}
