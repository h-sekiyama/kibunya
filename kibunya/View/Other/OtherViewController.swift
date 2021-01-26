import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class OtherViewController: UIViewController {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
    // PROアップグレードボタン
    @IBOutlet weak var proButtonLabel: UILabel!
    @IBOutlet var upgradeProButton: UITapGestureRecognizer!
    // PROモードにアップグレード
    @IBAction func upgradePro(_ sender: Any) {
        let dialog = UIAlertController(title: "PROにアップグレード", message: "PROにアップグレードすると以下の機能が追加されます\n\n日記の文字数が無制限に\n日記の写真を高画質で送れる\n日記画像の保存機能\n広告非表示", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "アップグレード", style: .default,
            handler: { action in
                do {
                    self.startIndicator()
                    IAPManager.shared.buy(productIdentifier: "kazoku_diary_pro_mode")
                }
            }))
        dialog.addAction(UIAlertAction(title: "購入を復元", style: .default,
            handler: { action in
                do {
                    self.startIndicator()
                    IAPManager.shared.restore()
                }
            }))
        dialog.addAction(UIAlertAction(title: "しない", style: .cancel, handler: nil))
        // 生成したダイアログを実際に表示します
        self.present(dialog, animated: true, completion: nil)
    }
    
    // 家族追加画面へ遷移
    @IBAction func addFamilyButton(_ sender: Any) {
        let addFamilyViewController = UIStoryboard(name: "AddFamilyViewController", bundle: nil).instantiateViewController(withIdentifier: "AddFamilyViewController") as UIViewController
        addFamilyViewController.modalPresentationStyle = .fullScreen
        self.present(addFamilyViewController, animated: false, completion: nil)
    }
    
    // 家族リスト表示画面へ遷移
    @IBAction func showFamilyList(_ sender: Any) {
        let showFamilyViewController = UIStoryboard(name: "ShowFamilyViewController", bundle: nil).instantiateViewController(withIdentifier: "ShowFamilyViewController") as UIViewController
        showFamilyViewController.modalPresentationStyle = .fullScreen
        self.present(showFamilyViewController, animated: false, completion: nil)
    }
    
    // プロフィール変更画面へ遷移
    @IBAction func changeNameButton(_ sender: Any) {
        let changeNameViewController = UIStoryboard(name: "ChangeNameViewController", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameViewController") as UIViewController
        changeNameViewController.modalPresentationStyle = .fullScreen
        self.present(changeNameViewController, animated: false, completion: nil)
    }
    
    // ログアウト
    @IBAction func logoutButton(_ sender: Any) {
        let dialog = UIAlertController(title: "ログアウト", message: "ログアウトしますか？", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .default,
            handler: { action in
                do {
                    // PUSH通知用のデバイストークンをニフクラサーバから削除
                    Functions.deleteDeviceTokenFromNCMB()
                    
                    try Auth.auth().signOut()
                    let signUpViewController = UIStoryboard(name: "SignUpViewController", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as UIViewController
                    signUpViewController.modalPresentationStyle = .fullScreen
                    self.present(signUpViewController, animated: true, completion: nil)
                } catch let error {
                    print(error)
                }
            }))
        dialog.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        // 生成したダイアログを実際に表示します
        self.present(dialog, animated: true, completion: nil)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 既にPROモードならアップグレードボタンは非活性にする
        if (UserDefaults.standard.billingProMode ?? false) {
            proButtonLabel.text = "PROアップグレード済み"
            upgradeProButton.isEnabled = false
        } else {
            IAPManager.shared.delegate = self
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
        tabBarView.otherButton.setBackgroundImage(UIImage(named: "tab_image2_on"), for: .normal)
    }
}

extension OtherViewController: IAPManagerDelegate {
    //購入が完了した時
    func iapManagerDidFinishPurchased() {
        self.dismissIndicator()
        let dialog = UIAlertController(title: "購入完了", message: "購入ありがとうございます！ひきつづき家族ダイアリーをお楽しみ下さい！", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(dialog, animated: true, completion: nil)
        UserDefaults.standard.billingProMode = true
    }
    //購入に失敗した時
    func iapManagerDidFailedPurchased() {
        self.dismissIndicator()
        let dialog = UIAlertController(title: "購入失敗", message: "購入に失敗しました", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
    //リストアが完了した時
    func iapManagerDidFinishRestore(_ productIdentifiers: [String]) {
        self.dismissIndicator()
        for identifier in productIdentifiers {
            if identifier == "kazoku_diary_pro_mode" {
                let dialog = UIAlertController(title: "復元完了", message: "復元完了しました！ひきつづき家族ダイアリーをお楽しみ下さい！", preferredStyle: .alert)
                dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(dialog, animated: true, completion: nil)
                UserDefaults.standard.billingProMode = true
            }
        }
    }
    //1度もアイテム購入したことがなく、リストアを実行した時
    func iapManagerDidFailedRestoreNeverPurchase() {
        self.dismissIndicator()
        let dialog = UIAlertController(title: "復元失敗", message: "復元できませんでした", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
    //リストアに失敗した時
    func iapManagerDidFailedRestore() {
        self.dismissIndicator()
        let dialog = UIAlertController(title: "復元失敗", message: "復元に失敗しました", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
    //特殊な購入時の延期の時
    func iapManagerDidDeferredPurchased() {
        self.dismissIndicator()
        let dialog = UIAlertController(title: "購入失敗", message: "購入に失敗しました", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}
