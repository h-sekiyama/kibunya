import Foundation
import FirebaseFirestore

class Kibuns: NSObject {
    var uid: String?
    var name: String?
    var user_id: Int?
    var kibun: Int?
    var text: String?
    var date: Date?
    
    init(document: QueryDocumentSnapshot) {
        self.uid = document.documentID
        let Dic = document.data()
        self.name = Dic["name"] as? String
        self.user_id = Dic["user_id"] as? Int
        self.kibun = Dic["kibun"] as? Int
        self.text = Dic["text"] as? String
        self.date = Dic["date"] as? Date
    }
}
