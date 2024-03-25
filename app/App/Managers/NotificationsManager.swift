//
//  AuthenticationModel.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import Foundation
import NotificationCenter

class NotificationsManager {
    static let shared = NotificationsManager()

    func registerFromRemoteNotifications(completion: @escaping (Bool, Error?) -> Void) {
        let center  = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            completion(success, error)
        }
    }
}
