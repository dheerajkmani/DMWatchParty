//
//  HomeViewController.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 16/08/23.
//

import UIKit
import Firebase
import NVActivityIndicatorView

class HomeViewController: UIViewController {
    
    @IBOutlet weak var hacakthonLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var emailTextField: UITextField!

    var currentUser: User!

    var actIndicator: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.backgroundColor()
        
        actIndicator = NVActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0), type: .ballScaleRippleMultiple, color: .buttonColor(), padding: nil)
        self.view.addSubview(actIndicator)
        actIndicator.center = view.center
        actIndicator.center.y = view.center.y - 150.0
        
        self.playButton.backgroundColor = UIColor.buttonColor()
        self.playButton.tintColor = UIColor.textColor()
        self.playButton.layer.cornerRadius = 25
        self.playButton.layer.masksToBounds = true
        
        self.hacakthonLabel.textColor = UIColor.textColor()
        
        self.setupTextField(emailTextField)
        
        if let userEmail = UserDefaults.standard.value(forKey: "user_email") as? String {
            emailTextField.text = userEmail
        }
        
    }
    
    func setupTextField(_ textField: UITextField) {
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter your email",
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
    
    func validateEmail(_ enteredEmail:String) -> Bool
    {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    @IBAction func letsGoAction(_ sender: UIButton) {
        self.signInAction()
    }
    
    func signInAction() {
        
        self.view.endEditing(true)
        
        guard let email = self.emailTextField.text,email != "" else {
            // Show email alert
            self.showToast(message: "Please enter email id")
            return
        }
        
        guard let isValidEmail = self.validateEmail(email) as Bool?, isValidEmail else {
            self.showToast(message: "Please enter valid email id")
            return
        }
        actIndicator.startAnimating()
        Auth.auth().fetchSignInMethods(forEmail: email) { emailExist, _  in
            if emailExist != nil {
                self.loginUser(email.replacingOccurrences(of: " ", with: ""))
            } else {
                self.createUser(email)
            }
        }
        
    }
    
    func openWatchPartyFromDeepLink(_ chatRoomId: String) {
        
        actIndicator.startAnimating()

        guard let email = emailTextField.text else { return }
        
        Auth.auth().fetchSignInMethods(forEmail: email) { emailExist, _  in
            if emailExist != nil {
                self.loginUser(email.replacingOccurrences(of: " ", with: ""), isDeepLinking: true, chatRoomId: chatRoomId)
            } else {
                self.createUser(email, isDeepLinking: true, chatRoomId: chatRoomId)
            }
        }

    }
    
    func openWatchPartyScreen(_ chatRoomId: String, user: User, isCreatedByMe: Bool = false) {
                
        actIndicator.stopAnimating()

        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc : WatchPartyViewController = storyboard.instantiateViewController(withIdentifier: "WatchPartyViewController") as! WatchPartyViewController
        vc.chatRoomId = chatRoomId
        vc.isCreatedByMe = isCreatedByMe
        vc.chatRoom = ChatRoom(id: chatRoomId, users: [user])
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
    
    func openPlayerScreen() {
        
        actIndicator.stopAnimating()

        let playerViewController = MuviPlayerViewController.shared
        playerViewController.currentUser = self.currentUser
        self.navigationController?.pushViewController(playerViewController, animated: true)
    }
    
}

extension HomeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
    
}

extension HomeViewController {
    
    func createUser(_ email: String, isDeepLinking: Bool = false, chatRoomId: String = "") {
        
        Auth.auth().createUser(withEmail: email, password: "password") { authResult, error in
            if let user = authResult?.user {
                print("User registration successful ", user.email?.components(separatedBy: "@").first ?? "")
                
                UserDefaults.standard.setValue(email, forKey: "user_email")
                UserDefaults.standard.setValue(user.uid, forKey: "user_id")
                
                self.currentUser = User(id: user.uid,
                                        email: user.email!,
                                        name: user.email?.components(separatedBy: "@").first ?? "",
                                        isChatRoomStartedBy: false)
                
                if isDeepLinking { self.openWatchPartyScreen(chatRoomId, user: self.currentUser, isCreatedByMe: false) }
                else { self.openPlayerScreen() }

            } else if let error = error {
                self.actIndicator.stopAnimating()
                self.showToast(message: error.localizedDescription)
                print(error.localizedDescription)
            }
        }
    }
    
    func loginUser(_ email: String, isDeepLinking: Bool = false, chatRoomId: String = "") {
        
        Auth.auth().signIn(withEmail: email, password: "password") { authResult, error in
            if let user = authResult?.user {
                print("User registration successful ", user.email?.components(separatedBy: "@").first ?? "")
                
                UserDefaults.standard.setValue(email, forKey: "user_email")
                UserDefaults.standard.setValue(user.uid, forKey: "user_id")
                
                self.currentUser = User(id: user.uid,
                                        email: user.email!,
                                        name: user.email?.components(separatedBy: "@").first ?? "",
                                        isChatRoomStartedBy: false)

                if isDeepLinking { self.openWatchPartyScreen(chatRoomId, user: self.currentUser, isCreatedByMe: false) }
                else { self.openPlayerScreen() }
                
            } else if let error = error {
                self.actIndicator.stopAnimating()
                self.showToast(message: error.localizedDescription)
                print(error.localizedDescription)
            }
        }
    }
    
}
