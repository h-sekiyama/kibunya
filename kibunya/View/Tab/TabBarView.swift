import Foundation
import UIKit

class TabBarView: NSObject {

    @IBOutlet weak var tab: UIStackView!
    
    // 現在画面表示を担当しているViewControllerインスタンスを保持しておくプロパティ
    weak var owner: UIViewController?
    
    // 気分リストボタン
    @IBAction func kibunButton(_ sender: Any) {
        let mainViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as UIViewController
        mainViewController.modalPresentationStyle = .fullScreen
        owner?.present(mainViewController, animated: false, completion: nil)
    }
    // 気分入力ボタン
    @IBAction func InputKibunButton(_ sender: Any) {
        let inputKibunViewController = UIStoryboard(name: "InputKibunViewController", bundle: nil).instantiateViewController(withIdentifier: "InputKibunViewController") as UIViewController
        inputKibunViewController.modalPresentationStyle = .fullScreen
        owner?.present(inputKibunViewController, animated: false, completion: nil)
    }
    // その他ボタン
    @IBAction func otherButton(_ sender: Any) {
        let otherViewController = UIStoryboard(name: "OtherViewController", bundle: nil).instantiateViewController(withIdentifier: "OtherViewController") as UIViewController
        otherViewController.modalPresentationStyle = .fullScreen
        owner?.present(otherViewController, animated: false, completion: nil)
    }
    
    
    var tabView: UIView!

    override init() {
        super.init()
        tabView = UINib(nibName: "TabBarView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as? UIView
    }
}
