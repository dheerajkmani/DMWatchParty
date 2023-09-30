//
//  WatchPartyViewController.swift
//  DMWatchParty
//
//  Created by Soubhagya  on 17/08/23.
//

import UIKit
import Firebase
import MuviPlayer
import CoreMedia
import AVFoundation
import MessageKit
import InputBarAccessoryView

class WatchPartyViewController: UIViewController {
    
    @IBOutlet weak var playerViewContainer: UIView!
    
    @IBOutlet weak var partyButtonView: UIView!
    
    @IBOutlet weak var chatButton: UIButton!
    
    @IBOutlet weak var chatButtonView: UIView!
    
    @IBOutlet weak var detailsButton: UIButton!
    
    @IBOutlet weak var detailsButtonView: UIView!
    
    @IBOutlet weak var messageView: UIView!
    
    var messagesViewController: MessagesViewController!
    
    var chatRoomId: String!
    
    var currentSender: MessageKit.SenderType
    
    var otherSender: MessageKit.SenderType
    
    var playerViewController = MuviPlayerViewController.shared
    
    var isPlaying: Bool = false
    
    var messages = [Message]()
    
    var databaseReference: DatabaseReference!
    
    var isCreatedByMe: Bool = false
    
    var chatRoom: ChatRoom!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        currentSender = Sender(senderId: "self", displayName: "John")
        otherSender = Sender(senderId: "other", displayName: "Katy")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        currentSender = Sender(senderId: "self", displayName: "John")
        otherSender = Sender(senderId: "other", displayName: "Katy")
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialSetup()
        self.setUpPlayerView()
        
        databaseReference = Database.database().reference().child("chatrooms")
        self.addUserInChatRoomDatabase()
        observeMessages()
        observePlayerState()
        
        playerViewController.watchPartyDelegate = self
        self.setupMessageKit()
        // self.closeWatchPartyObserver()
        self.observeUserInChatRoom()
        
        let customBackButton = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action: #selector(customBackButtonTapped))
        navigationItem.leftBarButtonItem = customBackButton
    }
    
    private func setupMessageKit() {
        
        self.messagesViewController = MessagesViewController()
        
        let messageInputBar = self.messagesViewController.messageInputBar
        messageInputBar.delegate = self
        messageInputBar.backgroundColor = UIColor.placeholderColor()
        messageInputBar.backgroundView.backgroundColor = UIColor.placeholderColor()
        messageInputBar.inputTextView.textColor = .white
        messageInputBar.inputTextView.placeholderLabel.text = "Write your message..."
        
        self.messagesViewController.messagesCollectionView.messagesDataSource = self
        self.messagesViewController.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesViewController.messagesCollectionView.messagesDisplayDelegate = self
        self.messagesViewController.messagesCollectionView.backgroundColor = UIColor.placeholderColor()
        
        if let layout = self.messagesViewController.messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
        
        messageInputBar.delegate = self
        self.addChild(messagesViewController)
        self.messageView.addSubview(messagesViewController.view)
        self.messageView.backgroundColor =  UIColor.placeholderColor()
        self.messagesViewController.view.frame = self.messageView.bounds
        
        self.messagesViewController.view.backgroundColor = UIColor.darkGray
        _ = self.messagesViewController.view.subviews.map({ view in
            view.backgroundColor = .clear
        })
        
        self.messagesViewController.didMove(toParent: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setUpPlayerView()
    }
    
    func initialSetup(){
        self.view.backgroundColor = UIColor.backgroundColor()
        self.playerViewContainer.backgroundColor = UIColor.black
        let customBackButtonImage = UIImage(named: "chevron.backward")
        // Set the custom back button appearance
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.backIndicatorImage = customBackButtonImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = customBackButtonImage
        self.navigationController?.navigationBar.tintColor = UIColor.textColor()
        
        self.partyButtonView.backgroundColor = UIColor.placeholderColor()
        self.setButton(color: UIColor.buttonColor(), button: self.chatButton, view: self.chatButtonView, text: "Chat (\(self.chatRoom.users.count))", alpha: 1.0)
        self.setButton(color: UIColor.descriptionTextColor(), button: self.detailsButton, view: self.detailsButtonView, text: "Details", alpha: 0.5)
    }
    
    func setButton(color: UIColor, button: UIButton, view: UIView, text: String, alpha: CGFloat ){
        button.setTitle(text, for: .normal)
        button.titleLabel?.textColor =  color
        button.titleLabel?.alpha = alpha
        button.tintColor = color
        button.titleLabel?.font = UIFont.poppinsSemiBold(16)
        button.backgroundColor = UIColor.clear
        view.backgroundColor = color
    }
    
    @IBAction func detailsButtonAction(_ sender: Any) {

    }
    
    @IBAction func chatButtonAction(_ sender: Any) {

    }
    
    func setUpPlayerView(){
        self.playerViewContainer.backgroundColor = UIColor.black
        self.playerViewContainer.addSubview(playerViewController.playerView)
        self.playerViewController.playerView.frame = playerViewContainer.bounds
        self.playerViewController.playerView.controls?.backButton?.isHidden = true
        self.isPlaying = true
        self.playerViewController.playerView.isHidden = false
        self.playerViewController.initializePlayer(isFromPIP: false, isPlay: false)
    }
}

extension WatchPartyViewController { // Observer
    
    func observeUserInChatRoom() {
        
        databaseReference.child(chatRoomId).child("users").observe(.childAdded) { snapshot, _   in
            if let userData = snapshot.value as? [String: Any] {
                if let userId = userData["userId"] as? String,
                   let userEmail = userData["userEmail"] as? String,
                   let userName = userData["userName"] as? String,
                   let isChatRoomStartedBy = userData["isChatRoomStartedBy"] as? Bool {
                    
                    self.addUser(User(id: userId, email: userEmail,
                                      name: userName, isChatRoomStartedBy: isChatRoomStartedBy))
                }
            }
        }
        
        databaseReference.child(chatRoomId).child("users").observe(.childRemoved) { snapshot, _   in
            if let userData = snapshot.value as? [String: Any] {
                if let userId = userData["userId"] as? String,
                   let userEmail = userData["userEmail"] as? String,
                   let userName = userData["userName"] as? String,
                   let isChatRoomStartedBy = userData["isChatRoomStartedBy"] as? Bool {
                    
                    self.removeUser(User(id: userId, email: userEmail,
                                         name: userName, isChatRoomStartedBy: isChatRoomStartedBy))
                }
            }
        }

    }
    
    func closeWatchPartyObserver() {
        
        databaseReference.child("closed").observe(.childAdded) { snapshot in
            if let messageData = snapshot.value as? [String: Any] {
                if let senderId = messageData["senderId"] as? String,
                   let chatRoomId = messageData["chatRoomId"] as? String {
                    
                    if self.chatRoomId == chatRoomId,
                       senderId != UserDefaults.standard.string(forKey: "user_id") {
                        self.playerViewController.playerView.player.pause()
                        self.showAlertAndClose()
                    }
                    
                }
            }
        }
        
    }
    
    func observeMessages() {
        
        databaseReference.child(chatRoomId).child("messages").observe(.childAdded) { snapshot, data  in
            
            if let messageData = snapshot.value as? [String: Any] {
                if let senderId = messageData["senderId"] as? String,
                   let userName = messageData["userName"] as? String,
                   let text = messageData["text"] as? String,
                   let timestamp = messageData["timestamp"] as? TimeInterval {
                    
                    let userInfo: MessageKit.SenderType
                    
                    
                    if let userId = Auth.auth().currentUser?.uid, userId == senderId {
                        userInfo = self.getCurrentUser()
                    }
                    else {
                        userInfo = self.getOtherUser()
                    }
                    
                    let message = Message(sender: userInfo,
                                          messageId: UUID().uuidString,
                                          sentDate: Date(timeIntervalSince1970: timestamp),
                                          kind: .text(text),
                                          senderId: userInfo.senderId,
                                          userName: userName,
                                          text: text,
                                          timestamp: timestamp)
                    self.messages.append(message)
                    self.messagesViewController.messagesCollectionView.reloadData()
                }
            }
        }
    }
    
    func observePlayerState() {
        databaseReference.child(chatRoomId).child("player").observe(.childAdded) { snapshot  in
            if let playerData = snapshot.value as? [String: Any] {
                if let senderId = playerData["senderId"] as? String,
                   let userName = playerData["userName"] as? String {
                    
                    self.databaseReference.child(self.chatRoomId).child("player").removeValue { _, _ in }
                    
                    if let playedTime = playerData["playedTime"] as? NSNumber  {
                        guard senderId != UserDefaults.standard.string(forKey: "user_id") else { return }
                        self.updatePlayer(playedTime)
                    }
                    
                    if let playerState = playerData["playerState"] as? String, playerState == "1" {
                        self.playerViewController.playerView.player.play()
                    } else if let playerState = playerData["playerState"] as? String, playerState == "0" {
                        self.playerViewController.playerView.player.pause()
                    }
                    
                }
            }
        }
        
    }
    
}

extension WatchPartyViewController { // Sender
    
    
    func addUser(_ user: User) {
        
        if let index = self.chatRoom.users.firstIndex(where: { $0.id == user.id }) {
            self.chatRoom.users.remove(at: index)
        }
        self.chatRoom.users.append(user)
        self.chatButton.setTitle("Chat (\(self.chatRoom.users.count))", for: .normal)

    }
    
    func removeUser(_ user: User) {
        
        if let index = self.chatRoom.users.firstIndex(where: { $0.id == user.id }) {
            self.chatRoom.users.remove(at: index)
        }
        self.chatButton.setTitle("Chat (\(self.chatRoom.users.count))", for: .normal)
        
        if user.isChatRoomStartedBy, Auth.auth().currentUser!.uid != user.id {
            self.playerViewController.playerView.player.pause()
            self.showAlert(title: "Watch Party!",
                           message: "Watch Party has been ended.",
                           haveCancelButton: false, okAction: self.closeActionForViewer)
        }
        
        if self.chatRoom.users.count == 0 {
            Utility.shared.deleteChatRoom(self.chatRoom.id)
        }
    }
    
    func addUserInChatRoomDatabase() {
        if let user = Auth.auth().currentUser {
            let message = [ "userId": user.uid,
                            "userEmail": user.email!,
                            "userName": Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "",
                            "isChatRoomStartedBy": self.isCreatedByMe ] as [String : Any]
            
            databaseReference.child(chatRoomId).child("users").child(user.uid).setValue(message)
        }
    }
    
    func deleteUserFromChatRoomDatabase() {
        if let userId = Auth.auth().currentUser?.uid {
            Utility.shared.deleteUser(userId: userId, in: self.chatRoom.id)
        }
    }
    
    func getCurrentUser() -> SenderType {
        currentSender = Sender(senderId: "self", displayName: Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "")
        return currentSender
    }
    
    func getOtherUser() -> SenderType {
        otherSender = Sender(senderId: "other", displayName: Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "")
        return otherSender
    }
    
    func sendMessage(text: String) {
        if let userId = Auth.auth().currentUser?.uid {
            let message = [ "senderId": userId,
                            "userName": Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "",
                            "text": text,
                            "timestamp": ServerValue.timestamp() ] as [String : Any]
            
            databaseReference.child(chatRoomId).child("messages").childByAutoId().setValue(message)
        }
    }
    
    func updatePlayer(_ seekTime: NSNumber) {
        
        let item = MuviPlayerItem(url: (self.playerViewController.playerView.player?.currentItem?.asset as? AVURLAsset)!.url)
        
        let seekTime = CMTimeMake(value: Int64(seekTime), timescale: 1)
        self.playerViewController.playerView.replacePlayer(item: item, time: seekTime)
        
    }
    
    func playPauseVideo(_ state: String? = nil, playedTime: NSNumber? = nil) {
        
        if let userId = Auth.auth().currentUser?.uid {
            var playerState = [
                "senderId": userId,
                "userName": Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? ""
            ] as [String : Any]
            
            if let state {
                playerState.updateValue(state, forKey: "playerState")
            }
            if let playedTime {
                playerState.updateValue(playedTime, forKey: "playedTime")
            }
            
            databaseReference.child(chatRoomId).child("player").childByAutoId().setValue(playerState)
        }
        
    }
    
}

extension WatchPartyViewController { // Back button and Alert Actions
    
    @objc func customBackButtonTapped() {
        if isCreatedByMe { self.showAlertAndClose() }
        else { self.closeActionForViewer() }
    }
    
    func closeActionForCreator() {
        self.playerViewController.playerView.player.replaceCurrentItem(with: nil)
        Utility.shared.closeChatRoom(self.chatRoomId)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func closeActionForViewer() {
        self.playerViewController.playerView.player.replaceCurrentItem(with: nil)
        self.deleteUserFromChatRoomDatabase()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func showAlertAndClose() {
        
        if isCreatedByMe {
            self.showAlert(title: "Close Watch Party!", message: "Do you want to close the current watch party?", haveCancelButton: true, okAction: self.closeActionForCreator)
        } else {
            self.showAlert(title: "Watch Party!", message: "Watch Party has been ended.", haveCancelButton: false, okAction: self.closeActionForViewer)
        }
        
    }
    
}

/*
 extension WatchPartyViewController: UITableViewDataSource {
 
 func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 return messages.count
 }
 
 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
 let message = messages[indexPath.row]
 cell.configure(with: message)
 return cell
 }
 
 }*/

extension WatchPartyViewController: WatchPartyPlayerDelegate {
    
    func playerDidPlay() {
        playPauseVideo("1")
    }
    
    func playerDidPause() {
        playPauseVideo("0")
    }
    
    func playerDidChanged(currentTime: NSNumber) {
        playPauseVideo(playedTime: currentTime)
    }
    
    func playerDidEnd() {
        
    }
    
    
}

extension WatchPartyViewController: MessagesDataSource  {
    
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return self.messages.count
    }
    
    func messageForItem(at indexPath: IndexPath,
                        in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return self.messages[indexPath.section]
    }
    
    func messageBottomLabelAttributedText(for message: MessageType,
                                          at indexPath: IndexPath) -> NSAttributedString? {
        
        let name = self.messages[indexPath.section].userName
        return NSAttributedString(string: name, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor.textColor()])
    }
    
}

extension WatchPartyViewController: MessagesDisplayDelegate {
    
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.placeholderColor()
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubble
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath,
                   in messagesCollectionView: MessagesCollectionView) -> UIColor {
        .white
    }
    
}

extension WatchPartyViewController: MessagesLayoutDelegate {
    
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath,
                                  in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageTopLabelAlignment(for message: MessageType, at indexPath: IndexPath,
                                  in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        
        if self.messages[indexPath.section].userName == "Katy" {
            return LabelAlignment(textAlignment: .left, textInsets: .zero)
        } else {
            return LabelAlignment(textAlignment: .right, textInsets: .zero)
        }
    }
    
    func messageBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath,
                                     in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        
        if self.messages[indexPath.section].senderId == "self" {
            return LabelAlignment(textAlignment: .right, textInsets: .zero)
        }
        return LabelAlignment(textAlignment: .left, textInsets: .zero)
    }
    
}

extension WatchPartyViewController : InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        inputBar.contentView.backgroundColor = UIColor.placeholderColor()
        inputBar.inputTextView.text = ""
        
        self.sendMessage(text: text)
        
        self.messagesViewController.messagesCollectionView.reloadData()
        self.messagesViewController.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
    }
    
}
