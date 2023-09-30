//
//  MessageCell.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var userLabel: UILabel!

    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with message: Message) {
        userLabel.text = message.userName
        messageLabel.text = message.text
    }
    
}
