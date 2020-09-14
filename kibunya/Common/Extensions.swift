import Foundation
import UIKit

extension UIViewController {
    
    public static var isShowIndicator: Bool = false
    
    func startIndicator() {
        if (UIViewController.isShowIndicator == false) {
            let loadingIndicator = UIActivityIndicatorView(style: .large)

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
            UIViewController.isShowIndicator = true
        }
    }

    func dismissIndicator() {
        if (UIViewController.isShowIndicator == true) {
            self.view.subviews.forEach {
                if $0.tag == 999 {
                    $0.removeFromSuperview()
                }
            }
            UIViewController.isShowIndicator = false
        }
    }
}

enum BorderPosition {
    case top
    case left
    case right
    case bottom
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
    
    /// 影の色
    @IBInspectable var shadowColor: UIColor? {
      get {
        return layer.shadowColor.map { UIColor(cgColor: $0) }
      }
      set {
        layer.shadowColor = newValue?.cgColor
        layer.masksToBounds = false
      }
    }

    /// 影の透明度
    @IBInspectable var shadowAlpha: Float {
      get {
        return layer.shadowOpacity
      }
      set {
        layer.shadowOpacity = newValue
      }
    }
//
    /// 影のオフセット
    @IBInspectable var shadowOffset: CGSize {
      get {
       return layer.shadowOffset
      }
      set {
        layer.shadowOffset = newValue
      }
    }

    /// 影のぼかし量
    @IBInspectable var shadowRadius: CGFloat {
      get {
       return layer.shadowRadius
      }
      set {
        layer.shadowRadius = newValue
      }
    }
}

// ユーザーデフォルトに値をセットする処理
private let AuthVerificationIDKey = "authVerificationID"
private let CachedProfileIconKey = "cachedProfileIconKey"
extension UserDefaults {
    var authVerificationID: String? {
        set(newValue) {
            set(newValue, forKey: AuthVerificationIDKey)
            synchronize()
        } get {
            return string(forKey: AuthVerificationIDKey)
        }
    }
    
    var cachedProfileIconKey: String? {
        set(newValue) {
            set(newValue, forKey: CachedProfileIconKey)
            synchronize()
        } get {
            return string(forKey: CachedProfileIconKey)
        }
    }
}

extension UIImageView {
    func loadImageAsynchronously(url: URL?, defaultUIImage: UIImage? = nil) -> Void {

        if url == nil {
            self.image = defaultUIImage
            return
        }

        DispatchQueue.global().async {
            do {
                let imageData: Data? = try Data(contentsOf: url!)
                DispatchQueue.main.async {
                    if let data = imageData {
                        self.image = UIImage(data: data)
                    } else {
                        self.image = defaultUIImage
                    }
                }
            }
            catch {
                DispatchQueue.main.async {
                    self.image = defaultUIImage
                }
            }
        }
    }
}
