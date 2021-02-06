import Foundation
import FirebaseFirestore

class Comments: NSObject, Comparable {
    static func < (lhs: Comments, rhs: Comments) -> Bool {
        return lhs.time!.dateValue() > rhs.time!.dateValue()
    }
    
    var commentId: String?
    var name: String?
    var user_id: String?
    var text: String?
    var time: Timestamp?
    var diaryId: String?
    
    init(document: QueryDocumentSnapshot) {
        self.commentId = document.documentID
        let Dic = document.data()
        self.name = Dic["name"] as? String
        self.user_id = Dic["user_id"] as? String
        self.text = Dic["text"] as? String
        self.time = Dic["time"] as? Timestamp
        self.diaryId = Dic["diary_id"] as? String
    }
}
