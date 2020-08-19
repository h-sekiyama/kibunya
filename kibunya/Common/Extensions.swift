import Foundation
import UIKit

extension UIViewController {
    func startIndicator() {

        let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)

        loadingIndicator.center = self.view.center
        let grayOutView = UIView(frame: self.view.frame)
        grayOutView.backgroundColor = .black
        grayOutView.alpha = 0.6

        // 他のViewと被らない値を代入
        loadingIndicator.tag = 999
        grayOutView.tag = 999

        self.view.addSubview(grayOutView)
        self.view.addSubview(loadingIndicator)
        self.view.bringSubviewToFront(grayOutView)
        self.view.bringSubviewToFront(loadingIndicator)

        loadingIndicator.startAnimating()
    }

    func dismissIndicator() {
        self.view.subviews.forEach {
            if $0.tag == 999 {
                $0.removeFromSuperview()
            }
        }
    }
}

extension UIView {

    // 枠線の色
    @IBInspectable var borderColor: UIColor? {
        get {
            return layer.borderColor.map { UIColor(cgColor: $0) }
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    // 枠線のWidth
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    // 角丸設定
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}