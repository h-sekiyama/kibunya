import UIKit

class TestCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var kibunText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCell(kibuns: Kibuns) {
        self.name.text = kibuns.name as String
        self.kibunText.text = kibuns.text as String
    }
}
