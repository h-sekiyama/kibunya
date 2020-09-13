import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class OtherViewController: UIViewController {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    
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
