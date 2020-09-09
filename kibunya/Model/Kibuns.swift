import Foundation
import FirebaseFirestore

class Kibuns: NSObject, Comparable {
    static func < (lhs: Kibuns, rhs: Kibuns) -> Bool {
        return lhs.time!.dateValue() > rhs.time!.dateValue()
    }
    
    static func == (lhs: Kibuns, rhs: Kibuns) -> Bool {
       return lhs.user_id == rhs.user_id
    }
    
    var uid: String?
    var name: String?
    var user_id: String?
    var kibun: Int?
    var text: String?
    var date: String?
    var time: Timestamp?
    var documentId: String?
    var image: String?
    
    init(document: QueryDocumentSnapshot) {
        self.uid = document.documentID
        let Dic = document.data()
        self.name = Dic["name"] as? String
        self.user_id = Dic["user_id"] as? String
        self.kibun = Dic["kibun"] as? Int
        self.text = Dic["text"] as? String
        self.date = Dic["date"] as? String
        self.time = Dic["time"] as? Timestamp
        self.documentId = Dic["documentId"] as? String
        self.image = Dic["image"] as? String
    }
}
