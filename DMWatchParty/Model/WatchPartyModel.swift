//
//  WatchPartyModel.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import Foundation
import Firebase
import MessageKit

struct ChatRoom {
    
    let id: String
    
    // let name: String
    
    var users: [User]
}

struct User {
    
    let id: String
    
    let email: String
    
    let name: String
    
    var isChatRoomStartedBy: Bool
}

struct ChatMessage {
    
    let senderId: String
    
    let userName: String
    
    let text: String
    
    let timestamp: TimeInterval
}

struct PlayerData {
    
    let isPlaying: String
    
    let currentTime: NSNumber
}

struct Sender: SenderType {
    
    var senderId: String
    
    var displayName: String
}

struct Message: MessageType {
    
    var sender: MessageKit.SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKit.MessageKind
    
    var senderId: String
    
    var userName: String
    
    var text: String
    
    var timestamp: TimeInterval
}

/*
 extension Message {
   init(chatMessage: ChatMessage){
     let sender = Sender(senderId: chatMessage.senderId, displayName: chatMessage.userName)
     let date = Date(timeIntervalSince1970: chatMessage.timestamp)
     self.sender = sender
     self.messageId = UUID().uuidString
     self.sentDate = date
     self.kind = .text(chatMessage.text)

     self.senderId = chatMessage.senderId
     self.userName = chatMessage.userName
     self.text = chatMessage.text
     self.timestamp = chatMessage.timestamp
   }
 }
 */
