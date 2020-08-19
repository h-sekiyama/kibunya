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
    
    // 名前変更画面へ遷移
    @IBAction func changeNameButton(_ sender: Any) {
        let changeNameViewController = UIStoryboard(name: "ChangeNameViewController", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameViewController") as UIViewController
        changeNameViewController.modalPresentationStyle = .fullScreen
        self.present(changeNameViewController, animated: false, completion: nil)
    }
    
    // ログアウト
    @IBAction func logoutButton(_ sender: Any) {
        // TODO: ログアウト処理実装
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
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - 80, width: self.view.bounds.width, height: 80)
    }
}
