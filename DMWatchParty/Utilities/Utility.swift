//
//  Utility.swift
//  DMWatchParty
//
//  Created by Dheeraj Kumar Mani on 18/08/23.
//

import Foundation
import Firebase
import AVFoundation
import Toast

final class Utility {
    
    static let shared = Utility()
    
    func checkEmailExists(email: String, completion: @escaping (Bool) -> Void) {
        let usersRef = Database.database().reference().child("users")
        
        // Query the database to find if the given email exists
        usersRef.queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(true) // Email exists
            } else {
                completion(false) // Email doesn't exist
            }
        }
    }
    
    func startChatRoom(_ chatRoomName: String) {
        
        let ref = Database.database().reference()
        let chatroomRef = ref.child("chatrooms").child(chatRoomName) //.childByAutoId()
                
        chatroomRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting chat room: \(error.localizedDescription)")
            } else {
                print("Chat room deleted successfully.")
                UserDefaults.standard.removeObject(forKey: "user_chatroom_id")
            }
        }
        chatroomRef.child("closed").setValue(false) { error, snapchat in
            if let error = error {
                print("Error opening chatroom: \(error.localizedDescription)")
            } else {
                print("Chatroom opened successfully.")
                UserDefaults.standard.setValue(chatroomRef.description().components(separatedBy: "/").last!, forKey: "user_chatroom_id")
            }
        }
        chatroomRef.child("name").setValue(chatRoomName) { error, snapchat in }

    }
    
    func getUserIds() {
        let usersRef = Database.database().reference().child("chatrooms").child("users")
        
        usersRef.observeSingleEvent(of: .value) { snapshot in
            if let userDict = snapshot.value as? [String: Any] {
                let userIds = Array(userDict.keys)
                print("User IDs: \(userIds)")
            }
        }
    }
    
    func deleteUser(userId: String, in chatroomId: String) {
        let usersRef = Database.database().reference().child("chatrooms").child(chatroomId).child("users").child(userId)

        usersRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
            } else {
                print("User deleted successfully.")
            }
        }
    }
    
    func joinChatroom(chatroomId: String, userId: String) {
                
        let ref = Database.database().reference()
        let participantsRef = ref.child("chatrooms").child(chatroomId).child("participants")
        
        participantsRef.updateChildValues([userId: true]) { error, _ in
            if let error = error {
                print("Error joining chatroom: \(error.localizedDescription)")
            } else {
                print("Joined chatroom successfully.")
            }
        }
        
    }
    
    func getParticipantsCount(chatroomId: String) -> Int {
        
        let ref = Database.database().reference()
        let participantsRef = ref.child("chatrooms").child(chatroomId).child("participants")

        return 0
    }
    
    func observeChatroomMessages(chatroomId: String) {
        let ref = Database.database().reference()
        let messagesRef = ref.child("chatrooms").child(chatroomId).child("messages")
        
        messagesRef.observe(.childAdded) { snapshot in
            if let messageData = snapshot.value as? [String: Any] {
                // Process and display the message in your UI
            }
        }
    }
    
    func closeChatRoom(_ chatroomId: String) {
        
        let ref = Database.database().reference()
        let chatroomRef = ref.child("chatrooms").child(chatroomId)
        
        chatroomRef.child("closed").setValue(true) { error, _ in
            if let error = error {
                print("Error closing chatroom: \(error.localizedDescription)")
            } else {
                print("Chatroom closed successfully.")
                self.closeWatchPartyForOthers(chatroomId)
                self.deleteChatRoom(chatroomId)
            }
        }
    }
    
    func deleteChatRoom(_ chatRoomId: String) {
        let chatRoomRef = Database.database().reference().child("chatrooms").child(chatRoomId)
        chatRoomRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting chat room: \(error.localizedDescription)")
            } else {
                print("Chat room deleted successfully.")
            }
        }
    }
    
    func closeWatchPartyForOthers(_ chatroomId: String) {
        
        let ref = Database.database().reference()
        let chatroomRef = ref.child("chatrooms").child(chatroomId)

        if let userId = Auth.auth().currentUser?.uid {
            let message = [
                "senderId": userId,
                "chatRoomId": chatroomId
            ] as [String : Any]
            
            ref.child("chatrooms").child("closed").childByAutoId().setValue(message)
        }

    }
    
    func sendMessage(chatroomId: String, text: String) {
        
        let ref = Database.database().reference()
        let chatroomRef = ref.child("chatrooms").child(chatroomId)
        
        chatroomRef.observeSingleEvent(of: .value) { snapshot in
            if let chatroom = snapshot.value as? [String: Any],
               let isClosed = chatroom["closed"] as? Bool, isClosed {
                print("Chatroom is closed. Message not sent.")
                return
                
            } else if let chatroom = snapshot.value as? [String: Any],
                      let isClosed = chatroom["closed"] as? Bool, !isClosed {

                if let userId = Auth.auth().currentUser?.uid {
                    let message = [
                        "senderId": userId,
                        "userName": Auth.auth().currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "",
                        "text": text,
                        "timestamp": ServerValue.timestamp()
                    ] as [String : Any]
                    
                    ref.child("chatrooms").child(chatroomId).child("messages").childByAutoId().setValue(message)
                }

            }
        }
        
    }
    
}

extension UIViewController {
    
    func showToast(message:String){
        self.view.makeToast(message, duration: 3.0, position: .bottom)
    }
    
    func showAlert(title: String, message: String, okButtonTitle: String = "OK",
                   haveCancelButton: Bool = false, okAction: @escaping () -> ()) {
        
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        
        // Add a "Cancel" action
        if haveCancelButton {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // Handle "Cancel" button tap
                print("Cancel tapped")
            }
            alertController.addAction(cancelAction)
        }

        // Add a "OK" action
        let okAction = UIAlertAction(title: okButtonTitle, style: .default) { _ in
            // Handle "OK" button tap
            okAction()
        }
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func getSeekTime(from currentTime: CMTime?) -> NSNumber? {
        if let currentTime, let currentTimeInFloat = CMTimeGetSeconds(currentTime) as Float64? {
            return currentTimeInFloat as NSNumber
        }
        return nil
    }
    
}
