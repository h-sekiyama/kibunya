import UIKit
import Foundation
import FSCalendar
import Firebase
import FirebaseFirestore

class KibunCalendarModalViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance {
    // カレンダーデータ変数
    var writtenDate: [String]?
    // カレンダーView
    @IBOutlet weak var calendar: FSCalendar!
    // カレンダーを閉じる
    @IBAction func closeCalendar(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    override func  viewDidLoad() {
        super.viewDidLoad()
        
        changeWeekdayLabelText()
    }
    
    func changeWeekdayLabelText() {
        // 曜日を日本語にする
        self.calendar.calendarWeekdayView.weekdayLabels[0].text = "日"
        self.calendar.calendarWeekdayView.weekdayLabels[1].text = "月"
        self.calendar.calendarWeekdayView.weekdayLabels[2].text = "火"
        self.calendar.calendarWeekdayView.weekdayLabels[3].text = "水"
        self.calendar.calendarWeekdayView.weekdayLabels[4].text = "木"
        self.calendar.calendarWeekdayView.weekdayLabels[5].text = "金"
        self.calendar.calendarWeekdayView.weekdayLabels[6].text = "土"
        
        // 土日の色を変える
        self.calendar.calendarWeekdayView.weekdayLabels[0].textColor = UIColor.red
        self.calendar.calendarWeekdayView.weekdayLabels[1].textColor = UIColor(red: 138/255, green: 72/255, blue: 83/255, alpha: 1.0)
        self.calendar.calendarWeekdayView.weekdayLabels[2].textColor = UIColor(red: 138/255, green: 72/255, blue: 83/255, alpha: 1.0)
        self.calendar.calendarWeekdayView.weekdayLabels[3].textColor = UIColor(red: 138/255, green: 72/255, blue: 83/255, alpha: 1.0)
        self.calendar.calendarWeekdayView.weekdayLabels[4].textColor = UIColor(red: 138/255, green: 72/255, blue: 83/255, alpha: 1.0)
        self.calendar.calendarWeekdayView.weekdayLabels[5].textColor = UIColor(red: 138/255, green: 72/255, blue: 83/255, alpha: 1.0)
        self.calendar.calendarWeekdayView.weekdayLabels[6].textColor = UIColor.blue
    }
    
    // 選択された日付を取得
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let mainViewController = UIStoryboard(name: "MainViewController", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        mainViewController.displayedDate = date
        mainViewController.modalPresentationStyle = .fullScreen
        self.present(mainViewController, animated: false, completion: nil)
    }

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        if (writtenDate == nil) {
            return 0
        }
        if (writtenDate!.contains(Functions.getDateString(date: date))) {
            return 1
        } else {
            return 0
        }
    }
}
