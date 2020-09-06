import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class KibunDetailViewController:  UIViewController {
    
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
    // タブ定義
    var tabBarView: TabBarView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var textLabel: UITextView!
    
    // 戻るボタン
    @IBAction func backButton(_ sender: Any) {
        let mainViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        mainViewController.displayedDate = date
        mainViewController.modalPresentationStyle = .fullScreen
        self.present(mainViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.text = "\(Functions.getDate(timeStamp: time!)) \(Functions.getTime(timeStamp: time!))"
        userNameLabel.text = userName! + "の日記"
        textLabel.text = text!
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
}
