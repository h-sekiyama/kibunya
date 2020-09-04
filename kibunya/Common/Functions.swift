import Foundation
import UIKit
import FirebaseFirestore

class Functions {
    // 今日の日付けを返すメソッド
    public static func today() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: Date())
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
}
