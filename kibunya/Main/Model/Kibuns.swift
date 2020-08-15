import Foundation

class Kibuns: NSObject {
    var name: String
    var user_id: Int
    var kibun: Int
    var text: String
    var date: Date
    
    init(name: String, user_id: Int, kibun: Int, text: String, date: Date) {
        self.name = name as String
        self.user_id = user_id as Int
        self.kibun = kibun as Int
        self.text = text as String
        self.date = date as Date
    }
}
