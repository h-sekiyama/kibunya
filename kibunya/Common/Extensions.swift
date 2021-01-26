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
private let DevicetokenKey = "devicetokenKey"
private let NowInputDiaryText = "nowInputDiaryText"
private let SendStoreReview = "sendStoreReview"
private let ShowKibunListCount = "showKibunListCount"
private let BillingProMode = "billingProMode"
extension UserDefaults {
    // 認証ID
    var authVerificationID: String? {
        set(newValue) {
            set(newValue, forKey: AuthVerificationIDKey)
            synchronize()
        } get {
            return string(forKey: AuthVerificationIDKey)
        }
    }
    
    // プロフィールアイコン画像キー
    var cachedProfileIconKey: String? {
        set(newValue) {
            set(newValue, forKey: CachedProfileIconKey)
            synchronize()
        } get {
            return string(forKey: CachedProfileIconKey)
        }
    }
    
    // PUSH送信用のデバイストークン
    var devicetokenKey: Data? {
        set(newValue) {
            set(newValue, forKey: DevicetokenKey)
            synchronize()
        } get {
            return data(forKey: DevicetokenKey)
        }
    }
    
    // 入力中の日記文章
     var nowInputDiaryText: String? {
        set(newValue) {
            set(newValue, forKey: NowInputDiaryText)
            synchronize()
        } get {
            return string(forKey: NowInputDiaryText)
        }
    }
    
    // 日記リスト画面表示回数
    var showKibunListCount: Int? {
       set(newValue) {
           set(newValue, forKey: ShowKibunListCount)
           synchronize()
       } get {
           return integer(forKey: ShowKibunListCount)
       }
    }
    
    // ストアレビュー促進ダイアログの表示有無
    var sendStoreReview: Bool? {
       set(newValue) {
           set(newValue, forKey: SendStoreReview)
           synchronize()
       } get {
           return bool(forKey: SendStoreReview)
       }
    }
    
    // PROモード購入したかどうか
    var billingProMode: Bool? {
       set(newValue) {
           set(newValue, forKey: BillingProMode)
           synchronize()
       } get {
           return bool(forKey: BillingProMode)
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

// キーボード欄外タップでキーボード閉じる処理
extension UIViewController
{
    func setupToHideKeyboardOnTapOnView()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))

        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}

extension UITextField{
   @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}
