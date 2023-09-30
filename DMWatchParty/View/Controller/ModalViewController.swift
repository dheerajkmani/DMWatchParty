//
//  ModalViewController.swift
//  DMWatchParty
//
//  Created by Soubhagya  on 17/08/23.
//

import UIKit

protocol modalViewPresent: AnyObject {
  func disminssCurrentVC(isDisMiss: Bool, partyType: Int)
}

class ModalViewController: UIViewController {

  @IBOutlet weak var capsuleView: UIView!
  @IBOutlet weak var createPartyBtn: UIButton!
  @IBOutlet weak var modalView: UIView!
  @IBOutlet weak var joinPartyBtn: UIButton!
  @IBOutlet weak var cancelBtn: UIButton!

  weak var delegate: modalViewPresent?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.modalView.backgroundColor = UIColor.bottomColor()
    // Set top left and top right corner radius
    let cornerRadius: CGFloat = 20.0
    let maskPath = UIBezierPath(roundedRect: self.modalView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
    let maskLayer = CAShapeLayer()
    maskLayer.frame = self.modalView.bounds
    maskLayer.path = maskPath.cgPath
    self.modalView.layer.mask = maskLayer
    self.setModalButton(button: self.cancelBtn)
    self.setModalButton(button: self.createPartyBtn)
    self.setModalButton(button: self.joinPartyBtn)

    self.capsuleView.backgroundColor = UIColor.descriptionTextColor()
    self.capsuleView.layer.cornerRadius = 3
  }

  func setModalButton(button: UIButton){
    button.backgroundColor = UIColor.placeholderColor()
    button.tintColor = UIColor.textColor()
    button.titleLabel?.textColor = UIColor.textColor()
    button.titleLabel?.font = UIFont.poppinsMedium(13)
    button.layer.cornerRadius = 5
    button.layer.masksToBounds = true
  }

  @IBAction func cancelBtnAction(_ sender: Any) {
    self.dismiss(animated: true)
  }

  @IBAction func joinPartyAction(_ sender: Any) {
      
      self.dismiss(animated: true) {
          self.delegate?.disminssCurrentVC(isDisMiss: true, partyType: 1)
      }

  }

  @IBAction func createPartyAction(_ sender: Any) {
      
      self.dismiss(animated: true) {
          self.delegate?.disminssCurrentVC(isDisMiss: true, partyType: 0)
      }
      
  }
}
