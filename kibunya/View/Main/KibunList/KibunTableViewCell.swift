import UIKit
import Firebase
import FirebaseFirestore

class KibunTableViewCell: UITableViewCell {
    
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
    }
}
