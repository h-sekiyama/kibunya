import UIKit
import Firebase
import FirebaseFirestore

class CommentTableViewCell: UITableViewCell {
    
    // 投稿者名
    @IBOutlet weak var name: UILabel!
    // コメント本文
    @IBOutlet weak var commentText: UILabel!
    // 投稿時間
    @IBOutlet weak var time: UILabel!
    // 投稿者プロフアイコン
    @IBOutlet weak var userIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCell(comments: Comments) {
        self.name.text = comments.name
        self.commentText.text = comments.text
        self.time.text = Functions.getTime(timeStamp: comments.time!)
    }
}
