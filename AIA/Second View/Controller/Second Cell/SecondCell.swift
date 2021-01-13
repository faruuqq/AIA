//
//  SecondCell.swift
//  AIA
//
//  Created by Muhammad Faruuq Qayyum on 13/01/21.
//

import UIKit

class SecondCell: UITableViewCell {

    @IBOutlet weak var symbol1: UILabel!
    @IBOutlet weak var open1: UILabel!
    @IBOutlet weak var low1: UILabel!
    
    @IBOutlet weak var symbol2: UILabel!
    @IBOutlet weak var open2: UILabel!
    @IBOutlet weak var low2: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
