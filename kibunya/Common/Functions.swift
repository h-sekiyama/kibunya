import Foundation
import UIKit
import Firebase
import FirebaseFirestore
import NCMB

class Functions {
    // 今日の日付けを返すメソッド
    public static func today() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: Date())
    }
    
    // 渡したDate型が今日の日付けか判定するメソッド
    public static func isToday(date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        let dateStr = formatter.string(from: date)
        if (dateStr == today()) {
            return true
        } else {
            return false
        }
    }
    
    // タイムスタンプを年月日に変換して返すメソッド
    public static func getDate(timeStamp: Timestamp) -> String {
        let date = timeStamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: date)
    }
    
    // タイムスタンプを年月日に変換して返すメソッド2
    public static func getDateSlash(timeStamp: Timestamp) -> String {
        let date = timeStamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM月/日"
        return dateFormatter.string(from: date)
    }
    
    // タイムスタンプを時間に変換して返すメソッド
    public static func getTime(timeStamp: Timestamp) -> String {
        let date = timeStamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    // Date型を渡したら曜日月の年月日に変換して返すメソッド
    public static func getDateWithDayOfTheWeek(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateStr = formatter.string(from: date)
        formatter.locale = NSLocale(localeIdentifier: "ja_JP") as Locale?
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEE", options: 0, locale:  Locale.current)
        let weekStr = formatter.string(from:  date)
        return dateStr + " (" + weekStr + ")"
    }
    
    // Lineでメッセージを投稿
    public static func sendLineMessage(_ text: String)  {
        let lineSchemeMessage: String! = "line://msg/text/"
        var scheme: String! = lineSchemeMessage + text
     
        scheme = scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let messageURL: URL! = URL(string: scheme)
     
        self.openURL(messageURL)
    }
     
    // URLを開く
    static private func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // 本来であれば、指定したURLで開けないときの実装を別途行う必要がある
            print("failed to open..")
        }
    }
    
    // DocumentディレクトリのfileURLを取得
    public static func getDocumentsURL() -> NSURL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        return documentsURL
    }

    // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
    public static func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL!.path
    }
    
    // 端末内に保存している画像を取得するメソッド
    public static func loadImageFromPath(path: String) -> UIImage? {
        let image = UIImage(contentsOfFile: path)
        if image == nil {
            print("missing image at: \(path)")
        }
        return image
    }
    
    // 画像を端末に保存するメソッド
    public static func saveImage(image: UIImage, path: String ) {
        let jpegData = image.jpegData(compressionQuality: 0.01)
        do {
            try jpegData!.write(to: URL(fileURLWithPath: path), options: .atomic)
            UserDefaults.standard.cachedProfileIconKey = path
        } catch {
            print(error)
        }
    }
    
    // 汎用ボタンの有効無効の切り替え
    public static func updateButtonEnabled(button: UIButton, enabled: Bool) {
        if (enabled) {
            button.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
            button.isEnabled = true
        }  else {
            button.backgroundColor = UIColor(red: 225/255, green: 205/255, blue: 203/255, alpha: 1)
            button.isEnabled = false
        }
    }
    
    // 遷移アニメーション
    public static func presentAnimation(view: UIView) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
    }
    
    // Firebase StorageのURL取得
    public static func getStorageURL() -> StorageReference {
        #if kibunya_dev
            return Storage.storage().reference(forURL: "gs://kibunya-dev.appspot.com")
        #else
            return Storage.storage().reference(forURL: "gs://kibunya-app.appspot.com")
        #endif
    }
    
    // 自分のdeviceTokenとFamilyDocumentIdの紐付け
    public static func setFamilyIdWithDeviceToken(familyDocumentId: String) {
        //端末情報を扱うNCMBInstallationのインスタンスを作成
        let installation : NCMBInstallation = NCMBInstallation.currentInstallation
        //ローカルのinstallationをfetchして更新
        installation.fetchInBackground(callback: { result in
            switch result {
                case .success:
                    print("取得成功:\(installation)")
                    guard let deviceToken: Data = UserDefaults.standard.devicetokenKey else { return }
                    
                    installation.setDeviceTokenFromData(data: deviceToken)
                    installation["channels"] = [familyDocumentId]
                    installation.saveInBackground(callback: {results in
                        switch results {
                        case .success(_):
                            //上書き保存する
                            break
                        case .failure:
                            //端末情報検索に失敗した場合の処理
                            break
                        }
                    })
                case let .failure(error):
                    print(error)
            }
        })
    }
}
