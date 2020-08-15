import Foundation
import UIKit

class TabBarView: NSObject {

    @IBOutlet weak var tab: UIStackView!
    var sampleView: UIView!

    override init() {
        super.init()

        sampleView = UINib(nibName: "TabBarView", bundle: Bundle.main).instantiate(withOwner: self, options: nil).first as? UIView
    }
}
