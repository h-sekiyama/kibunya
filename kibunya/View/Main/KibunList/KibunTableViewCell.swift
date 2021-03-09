import UIKit
import Firebase
import FirebaseFirestore

class KibunTableViewCell: UITableViewCell {
    
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // 投稿者名
    @IBOutlet weak var name: UILabel!
    // 日記本文
    @IBOutlet weak var kibunText: UILabel!
    // 気分アイコン画像
    @IBOutlet weak var kibunImage: UIImageView!
    // 投稿時間
    @IBOutlet weak var time: UILabel!
    // 投稿者プロフアイコン
    @IBOutlet weak var userIcon: UIImageView!
    // 日記に画像が添付されてる時に表示する画像
    @IBOutlet weak var isExistImage: UIImageView!
    // コメントアイコン
    @IBOutlet weak var commentIcon: UIImageView!
    // コメントの数
    @IBOutlet weak var commentCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCell(kibuns: Kibuns) {
        self.name.text = kibuns.name
        self.kibunText.text = kibuns.text!.isEmpty ? "未入力" : kibuns.text
        self.kibunImage.image = UIImage(named: "kibunIcon\(kibuns.kibun ?? 0)")
        self.time.text = Functions.getTime(timeStamp: kibuns.time!)
        self.commentIcon.isHidden = true
        self.commentCount.isHidden = true
        
        defaultStore.collection("comments").whereField("diary_id", isEqualTo: kibuns.documentId!).getDocuments() { (snaps, error)  in
            if let err = error {
                print(err)
            } else {
                let commentCount: Int = snaps?.count ?? 0
                self.commentCount.text = String(commentCount)
                if (commentCount != 0) {
                    self.commentIcon.isHidden = false
                    self.commentCount.isHidden = false
                } else {
                    self.commentIcon.isHidden = true
                    self.commentCount.isHidden = true
                }
            }
        }
    }
}
