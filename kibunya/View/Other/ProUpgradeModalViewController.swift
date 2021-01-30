import Foundation
import UIKit

class ProUpgradeModalViewController: UIViewController {
    
    // アップグレードボタンタップ
    @IBAction func upgradePro(_ sender: Any) {
        self.startIndicator()
        IAPManager.shared.buy(productIdentifier: "kazoku_diary_pro_mode")
    }
    
    // リストアボタンタップ
    @IBAction func restorePro(_ sender: Any) {
        self.startIndicator()
        IAPManager.shared.restore()
    }
    
    // 閉じるボタンタップ
    @IBAction func closeModal(_ sender: Any) {
        let otherViewController = UIStoryboard(name: "OtherViewController", bundle: nil).instantiateViewController(withIdentifier: "OtherViewController") as UIViewController
        otherViewController.modalPresentationStyle = .fullScreen
        self.present(otherViewController, animated: false, completion: nil)
    }
    
    // モーダル外をタップ
    @IBAction func tapOverlay(_ sender: Any) {
        let otherViewController = UIStoryboard(name: "OtherViewController", bundle: nil).instantiateViewController(withIdentifier: "OtherViewController") as UIViewController
        otherViewController.modalPresentationStyle = .fullScreen
        self.present(otherViewController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IAPManager.shared.delegate = self
    }
}

extension ProUpgradeModalViewController: IAPManagerDelegate {
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
    
    //ログインや購入確認のアラートが出た時
    func iapManagerDidFinishItemLoad() {
//        self.dismissIndicator()
    }
}
