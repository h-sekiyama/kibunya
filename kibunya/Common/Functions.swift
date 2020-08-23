import Foundation
import UIKit

class Functions {
    // 今日の日付けを返すメソッド
    public static func today() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: Date())
    }
    
    /**
      Lineでメッセージを投稿
      - parameter text: 送りたいメッセージ内容
     */
    static func sendLineMessage(_ text: String)  {
     
        let lineSchemeMessage: String! = "line://msg/text/"
        var scheme: String! = lineSchemeMessage + text
     
        scheme = scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let messageURL: URL! = URL(string: scheme)
     
        self.openURL(messageURL)
    }
     
    /**
      URLを開く
      - parameter url: URL
     */
    static private func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // 本来であれば、指定したURLで開けないときの実装を別途行う必要がある
            print("failed to open..")
        }
    }
}
