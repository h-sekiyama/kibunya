import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class InputKibunViewController: UIViewController {
    
    // タブ定義
    var tabBarView: TabBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        
        // タブの表示位置を調整
        NSLayoutConstraint.activate([
            tabBarView.tab.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
