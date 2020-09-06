import UIKit
import Firebase
import FirebaseFirestore

class KibunTableViewCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var kibunText: UILabel!
    @IBOutlet weak var kibunImage: UIImageView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var userIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 初期化
        userIcon.image = UIImage(named: "no_image")
    }
    
    func setCell(kibuns: Kibuns) {
        self.name.text = kibuns.name
        self.kibunText.text = kibuns.text!.isEmpty ? "未入力" : kibuns.text
        self.kibunImage.image = UIImage(named: "kibunIcon\(kibuns.kibun ?? 0)")
        self.time.text = Functions.getTime(timeStamp: kibuns.time!)
    }
}
