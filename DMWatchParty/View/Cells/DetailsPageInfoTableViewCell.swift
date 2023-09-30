//
//  DetailsPageInfoTableViewCell.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import UIKit

class DetailsPageInfoTableViewCell: UITableViewCell {

  @IBOutlet weak var contentName: UILabel!
  @IBOutlet weak var watchTrailerBtn: UIButton!
  @IBOutlet weak var contentDuration: UILabel!
  @IBOutlet weak var btnStack: UIStackView!
  @IBOutlet weak var favBtn: UIButton!
  @IBOutlet weak var plusBtn: UIButton!
  @IBOutlet weak var shareBtn: UIButton!
  @IBOutlet weak var contentDesc: ExpandableLabel!
  @IBOutlet weak var watchTrailerView: UIView!
  @IBOutlet weak var mainButtonStackView: UIStackView!
  
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
      self.backgroundColor = UIColor.clear
      self.contentName.setLabelDefaultProperty(text:"John Wick (2014)",font: UIFont.poppinsBold(20),textColor: UIColor.textColor(),textAlignment: .left)
      self.contentName.numberOfLines = 2
      self.contentDesc.setLabelDefaultProperty(text: "",font: UIFont.poppinsRegular(13),textColor: UIColor.descriptionTextColor(),textAlignment: .left)
      self.contentDuration.setLabelDefaultProperty(text: "2h 23min",font: UIFont.poppinsRegular(12),textColor: .clear,textAlignment: .right)
      self.watchTrailerBtn.backgroundColor = UIColor.placeholderColor()
      self.watchTrailerBtn.tintColor = UIColor.textColor()
      self.watchTrailerBtn.layer.cornerRadius = self.watchTrailerBtn.frame.height / 2
      self.watchTrailerBtn.layer.masksToBounds = true
      self.watchTrailerBtn.setTitle("Watch Now", for: .normal)
      self.watchTrailerBtn.setTitleColor(UIColor.textColor(), for: .normal)
      self.watchTrailerBtn.titleLabel?.font = UIFont.poppinsRegular(12)
      self.watchTrailerView.backgroundColor = UIColor.clear
      //Button Property
      self.favBtn.tintColor = UIColor.textColor()
      self.plusBtn.tintColor = UIColor.textColor()
      self.shareBtn.tintColor = UIColor.textColor()
    }
  override func prepareForReuse() {
      super.prepareForReuse()
  }
}
