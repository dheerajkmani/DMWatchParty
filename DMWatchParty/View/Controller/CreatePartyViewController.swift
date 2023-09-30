//
//  CreatePartyViewController.swift
//  DMWatchParty
//
//  Created by Soubhagya  on 17/08/23.
//

import UIKit
import Firebase
import NVActivityIndicatorView

class CreatePartyViewController: UIViewController {
    
    @IBOutlet weak var goBigLabel: UILabel!
    
    @IBOutlet weak var posterView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var contentName: UILabel!
    
    @IBOutlet weak var createPartyButton: UIButton!
    
    @IBOutlet weak var chatRoomNameTextField: UITextField!

    @IBOutlet weak var chatNameLabel: UILabel!
    
    @IBOutlet weak var letsPartyTextLabel: UILabel!
    
    var partyType: Int = 0
    
    var currentUser: User!

    var actIndicator: NVActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.backgroundColor()
        
        actIndicator = NVActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0), type: .ballScaleRippleMultiple, color: UIColor.buttonColor(), padding: nil)
        self.view.addSubview(actIndicator)
        actIndicator.center = view.center
        actIndicator.center.y = view.center.y - 150.0

        let customBackButtonImage = UIImage(named: "chevron.backward")
        
        // Set the custom back button appearance
        self.navigationController?.navigationBar.backIndicatorImage = customBackButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = customBackButtonImage
        self.navigationController?.navigationBar.tintColor = UIColor.textColor()
        
        self.contentName.setLabelDefaultProperty(text: "John Wick (2014)", font: UIFont.poppinsBold(13), textColor: UIColor.textColor(), textAlignment: .left)
        self.letsPartyTextLabel.setLabelDefaultProperty(text: "Let's get the party started", font: UIFont.poppinsBold(20), textColor: UIColor.textColor(), textAlignment: .left)
        self.chatNameLabel.setLabelDefaultProperty(text: "Email:", font: UIFont.poppinsMedium(12) ,textColor: UIColor.textColor(), textAlignment: .left)
        
        self.setupTextField(chatRoomNameTextField)
        
        self.createPartyButton.backgroundColor = UIColor.buttonColor()
        self.createPartyButton.setTitle(partyType == 0 ? "Create Watch Party" : "Join Watch Party", for: .normal)
        self.createPartyButton.layer.cornerRadius = 8
        self.createPartyButton.tintColor = UIColor.textColor()
        self.createPartyButton.titleLabel?.font = UIFont.poppinsMedium(14)
        self.createPartyButton.layer.masksToBounds = true
        self.goBigLabel.setLabelDefaultProperty(text: "Go big! Watch and Chat with your friends", font: UIFont.poppinsBold(16) ,textColor: UIColor.descriptionTextColor(), textAlignment: .left)
        self.createPartyButton.addTarget(self, action: #selector(createParty), for: .touchUpInside)
        
        let customBackButton = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action: #selector(customBackButtonTapped))
        navigationItem.leftBarButtonItem = customBackButton
    }
    
    @objc func customBackButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupTextField(_ textField: UITextField) {
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter watch party name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        textField.backgroundColor = UIColor.placeholderColor()
        textField.tintColor = UIColor.textColor()
        textField.font = UIFont.poppinsRegular(13)
        textField.textColor = UIColor.textColor()
        textField.borderStyle = .none
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.descriptionTextColor().cgColor
        textField.delegate = self
    }

  @objc func createParty(){
      
      self.view.endEditing(true)
      actIndicator.startAnimating()
      
      if partyType == 0 {
          guard let chatroom = self.chatRoomNameTextField.text?.lowercased(),
                let chatroomId = chatroom.replacingOccurrences(of: " ", with: "-") as String?,chatroomId != "" else {
              self.showToast(message: "Please enter watch party name")
              actIndicator.stopAnimating()
              return
          }
          
          Utility.shared.startChatRoom(chatroomId)
          self.currentUser.isChatRoomStartedBy = true
          openWatchPartScreen(chatroomId, user: self.currentUser, isCreatedByMe: true)
          
      } else {
          
          guard let chatroomId = self.chatRoomNameTextField.text?.lowercased(),chatroomId != "" else {
              self.showToast(message: "Please enter watch party name")
              actIndicator.stopAnimating()
              return
          }
          if let userId = UserDefaults.standard.value(forKey: "user_id") as? String {

              let ref = Database.database().reference()
              let participantsRef = ref.child("chatrooms").child(chatroomId).child("participants")
              
              let chatroomRef = ref.child("chatrooms").child(chatroomId)
              
              chatroomRef.observeSingleEvent(of: .value) { snapshot, _  in
                  
                  if let chatroom = snapshot.value as? [String: Any],
                     let isClosed = chatroom["closed"] as? Bool, isClosed {
                      self.showToast(message: "Watch party is closed now.")
                      print("Chatroom is closed. Message not sent.")
                      self.actIndicator.stopAnimating()

                  } else if let chatroom = snapshot.value as? [String: Any],
                            let isClosed = chatroom["closed"] as? Bool, !isClosed {

                      self.openWatchPartScreen(chatroomId, user: self.currentUser)
                  }else{
                      self.actIndicator.stopAnimating()
                      self.showToast(message: "Please enter valid watch party.")
                  }
                  
              }


          }
      }

  }
    
    func openWatchPartScreen(_ chatRoomId: String, user: User, isCreatedByMe: Bool = false) {
                
        actIndicator.stopAnimating()

        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc : WatchPartyViewController = storyboard.instantiateViewController(withIdentifier: "WatchPartyViewController") as! WatchPartyViewController
        vc.chatRoomId = chatRoomId
        vc.isCreatedByMe = isCreatedByMe
        vc.chatRoom = ChatRoom(id: chatRoomId, users: [user])
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
}

extension CreatePartyViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}
