//
//  Hermes.swift
//  Hermes
//
//  Created by Shane Whitehead on 21/11/18.
//  Copyright © 2018 Kaizen Enteripises. All rights reserved.
//

import Foundation
import UserNotifications
import Hydra
import SwiftEventBus
import AudioToolbox

/**
 Provides customisation over how the notification is presented
 */
public struct AlertStyle {
  
  private(set) var sound: UNNotificationSound? = nil
  private(set) var vibrate: Bool = false
  
  public init(sound: UNNotificationSound?, vibrate: Bool) {
    self.sound = sound
    self.vibrate = vibrate
  }
  
  public static var defaultSoundOnly: AlertStyle {
    return AlertStyle(sound: UNNotificationSound.default, vibrate: false)
  }
  
  public static var defaultSoundAndVibrate: AlertStyle {
    return AlertStyle(sound: UNNotificationSound.default, vibrate: true)
  }
  
  public static var vibrateOnly: AlertStyle {
    return AlertStyle(sound: nil, vibrate: true)
  }
  
  public static var silent: AlertStyle {
    return AlertStyle(sound: nil, vibrate: false)
  }
}

// I could use CustomStringConvertible, but I don't want to mess with other possible
// implementations which might need to use that protocol for their own needs
// I could use RawRepresentable, but the optional support several limits its possible
// functionality and adds a whole bunch of unnecessary boiler plating
// This seems like a lot of work just to pass a String, but I want to provide a flexible
// API which just says, "I need some kind of String value" and provide a flexible
// means for people to provide it.  In this, I use enum's, as it provides a clear
// intention of what I want/have to support
// Yes, you could use a enum which implements RawRepresentable - but the code
// looks ugly with .rawValue all over the place - IMHO
public protocol StringIdentifiable {
  var stringIdentifier: String {get}
}

extension String: StringIdentifiable {
  public var stringIdentifier: String { return self }
}

public func ==<T : StringIdentifiable>(lhs: T, rhs: String) -> Bool {
  return lhs.stringIdentifier == rhs
}
public func ==<T : StringIdentifiable>(lhs: String, rhs: T) -> Bool {
  return lhs == rhs.stringIdentifier
}
public func !=<T : StringIdentifiable>(lhs: T, rhs: String) -> Bool {
  return lhs.stringIdentifier != rhs
}
public func !=<T : StringIdentifiable>(lhs: String, rhs: T) -> Bool {
  return lhs != rhs.stringIdentifier
}

/// Notification Service Error
public enum NotificationsServiceError: Error {
  case authorisationFailed
}

/**
 Builder for UIUserNotificationAction
 
 This allows you to use a single line to build the action on
 */
public class UserNotificationActionBuilder {
  
  var Identifier: String = ""
  var title: String = ""
  var options: UNNotificationActionOptions = []
  
  public init() {
  }
  
  public func withIdentifier(_ value: StringIdentifiable) -> UserNotificationActionBuilder {
    Identifier = value.stringIdentifier
    return self
  }
  
  public func withTitle(_ value: StringIdentifiable) -> UserNotificationActionBuilder {
    title = value.stringIdentifier
    return self
  }
  
  public func withOptions(_ value: UNNotificationActionOptions) -> UserNotificationActionBuilder {
    options = value
    return self
  }
  
  public func build() -> UNNotificationAction {
    return UNNotificationAction(
      identifier: Identifier,
      title: title,
      options: options)
  }
}

/// Extension to provide custom init method that supports StringIdentifiable
public extension UNNotificationAction {
  
  convenience init(identifier: StringIdentifiable, title: StringIdentifiable, options: UNNotificationActionOptions = []) {
    self.init(identifier: identifier.stringIdentifier, title: title.stringIdentifier, options: options)
  }
  
}

/// Extension to provide custom init method that supports StringIdentifiable
public extension UNTextInputNotificationAction {
  
  convenience init(identifier: StringIdentifiable,
                   title: StringIdentifiable,
                   options: UNNotificationActionOptions = [],
                   textInputButtonTitle: StringIdentifiable,
                   textInputPlaceholder: StringIdentifiable) {
    self.init(identifier: identifier.stringIdentifier,
              title: title.stringIdentifier,
              options: options,
              textInputButtonTitle: textInputButtonTitle.stringIdentifier,
              textInputPlaceholder: textInputPlaceholder.stringIdentifier)
  }
}

/// Extension to provide custom init method that supports StringIdentifiable
public extension UNNotificationCategory {
  
  convenience init(identifier: StringIdentifiable,
                   actions: [UNNotificationAction],
                   intentIdentifiers: [String],
                   options: UNNotificationCategoryOptions = []) {
    self.init(identifier: identifier.stringIdentifier, actions: actions, intentIdentifiers: intentIdentifiers, options: options)
  }
  
}

/// Promise based extension to NotificationCenter
public extension UNUserNotificationCenter {
  
  public func authorise(options: UNAuthorizationOptions) -> Promise<Void> {
    return Promise<Void>({ (fulfill, fail, _) in
      self.requestAuthorization(options: options, completionHandler: { (granted, error) in
        if let error = error {
          fail(error)
          return
        }
        guard granted else {
          fail(NotificationsServiceError.authorisationFailed)
          return
        }
        fulfill(())
      })
    })
  }
  
  public func removePendingNotificationRequests(withIdentifiers idetifiers: [StringIdentifiable]) {
    let stringIdetifiers = idetifiers.map { $0.stringIdentifier }
    removePendingNotificationRequests(withIdentifiers: stringIdetifiers)
  }
  
  public func removeDeliveredNotifications(withIdentifiers idetifiers: [StringIdentifiable]) {
    let stringIdetifiers = idetifiers.map { $0.stringIdentifier }
    removeDeliveredNotifications(withIdentifiers: stringIdetifiers)
  }
  
  public func pendingRequests(withIdentifier identifier: StringIdentifiable) -> Promise<[UNNotificationRequest]> {
    return pendingRequests().then { (requests: [UNNotificationRequest]) -> Promise<[UNNotificationRequest]> in
      let filtered = requests.filter { $0.identifier == identifier.stringIdentifier }
      return Promise<[UNNotificationRequest]>(resolved: filtered)
    }
  }
  
  public func deliveredNotifications(withIdentifier identifier: StringIdentifiable) -> Promise<[UNNotification]> {
    return deliveredNotifications().then { (requests: [UNNotification]) -> Promise<[UNNotification]> in
      let filtered = requests.filter { $0.request.identifier == identifier.stringIdentifier }
      return Promise<[UNNotification]>(resolved: filtered)
    }
  }
  
  public func pendingRequests() -> Promise<[UNNotificationRequest]> {
    return Promise<[UNNotificationRequest]>({ (fulfill, fail, _) in
      self.getPendingNotificationRequests(completionHandler: { (notifications) in
        fulfill(notifications)
      })
    })
  }
  
  public func settings() -> Promise<UNNotificationSettings> {
    return Promise<UNNotificationSettings>({ (fulfill, fail, _) in
      self.getNotificationSettings(completionHandler: { (settings) in
        fulfill(settings)
      })
    })
  }
  
  public func notificationCategories() -> Promise<Set<UNNotificationCategory>> {
    return Promise<Set<UNNotificationCategory>>({ (fulfill, fail, _) in
      self.getNotificationCategories(completionHandler: { (categories) in
        fulfill(categories)
      })
    })
  }
  
  public func deliveredNotifications() -> Promise<[UNNotification]> {
    return Promise<[UNNotification]>({ (fulfill, fail, _) in
      self.getDeliveredNotifications(completionHandler: { (notifications) in
        fulfill(notifications)
      })
    })
  }
  
  public func add(request: UNNotificationRequest) -> Promise<Void> {
    return Promise<Void>({ (fulfill, fail, _) in
      self.add(request, withCompletionHandler: { (error) in
        guard let error = error else {
          fulfill(()) // Ain't that just dumb
          return
        }
        fail(error)
      })
    })
  }
  
}

enum NotificationManagerPayload: String, Hashable {
  case response = "NotificationPayload.response"
}

protocol KeyPath {
  var path: String {get}
}

public enum NotificationManagerKey: String, KeyPath {
  case vibrate = "NotificationKey.vibrate"
  case postName = "NotificationKey.postName"
  public var path: String { return self.rawValue }
}

public struct NotificationServiceManager {
  public static let shared: NotificationService = MutableNotificationServiceManager.shared
}

/// This is provided for testing, to change the implementation of the NotificationService been used
public struct MutableNotificationServiceManager {
  public static var shared: NotificationService = DefaultNotificationService()
}

public protocol NotificationService: NSObjectProtocol {
  
  func set(categories: Set<UNNotificationCategory>)
  func response(from: Notification) -> UNNotificationResponse?
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           userInfo: [AnyHashable: Any]) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           userInfo: [AnyHashable: Any]) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           category: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           userInfo: [AnyHashable: Any],
           category: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           userInfo: [AnyHashable: Any],
           category: StringIdentifiable) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           thread: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           userInfo: [AnyHashable: Any],
           thread: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           userInfo: [AnyHashable: Any],
           thread: StringIdentifiable) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           category: StringIdentifiable,
           thread: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           userInfo: [AnyHashable: Any],
           category: StringIdentifiable,
           thread: StringIdentifiable) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           body: StringIdentifiable,
           alertStyle: AlertStyle,
           userInfo: [AnyHashable: Any],
           category: StringIdentifiable,
           thread: StringIdentifiable) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           title: StringIdentifiable,
           subtitle: StringIdentifiable?,
           body: StringIdentifiable,
           badge: NSNumber?,
           alertStyle: AlertStyle?,
           userInfo: [AnyHashable: Any]?,
           attachments: [UNNotificationAttachment]?,
           category: StringIdentifiable?,
           thread: StringIdentifiable?) -> Promise<Void>
  
  func add(identifier: StringIdentifiable,
           content: UNNotificationContent) -> Promise<Void>
  func add(identifier: StringIdentifiable,
           content: UNNotificationContent,
           trigger: UNNotificationTrigger) -> Promise<Void>
}

// This will need to become a protocol
/// Notification Service/Manager wrapped around the user notification center API
public class DefaultNotificationService: NSObject, NotificationService, UNUserNotificationCenterDelegate {
  
  let notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
  
  var triggerDelay: TimeInterval = 0.1
  
  public override init() {
    super.init()
    notificationCenter.delegate = self
  }
  
  public func set(categories: Set<UNNotificationCategory>) {
    notificationCenter.setNotificationCategories(categories)
  }
  
  public func response(from: Notification) -> UNNotificationResponse? {
    return from.userInfo?[NotificationManagerPayload.response] as? UNNotificationResponse
  }
  
  // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
    
    var requestIdentifier = response.notification.request.identifier
    let notificationUserInfo = response.notification.request.content.userInfo
    if let value = notificationUserInfo[NotificationManagerKey.postName.path] as? String {
      requestIdentifier = value
    }
    
    let userInfo: [AnyHashable: Any] = [NotificationManagerPayload.response: response]
    
    completionHandler()
    
    onBackgroundThreadDo {
      SwiftEventBus.post(requestIdentifier, userInfo: userInfo)
    }
  }
  
  // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    //    let userInfo = notification.request.content.userInfo
    //    if let vibrate = userInfo[NotificationManagerKey.vibrate.path] as? Bool {
    //      if vibrate {
    //        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    //      }
    //    }
    completionHandler([.alert, .sound, .badge])
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  subtitle: StringIdentifiable?,
                  body: StringIdentifiable,
                  badge: NSNumber?,
                  alertStyle: AlertStyle?,
                  userInfo: [AnyHashable: Any]?,
                  attachments: [UNNotificationAttachment]?,
                  category: StringIdentifiable?,
                  thread: StringIdentifiable?) -> Promise<Void> {
    let content = UNMutableNotificationContent()
    content.title = title.stringIdentifier
    if let subtitle = subtitle {
      content.subtitle = subtitle.stringIdentifier
    }
    content.body = body.stringIdentifier
    content.badge = badge
    
    var info: [AnyHashable: Any] = [:]
    if let userInfo = userInfo {
      info = userInfo
    }
    if let alertStyle = alertStyle {
      content.sound = alertStyle.sound
      if alertStyle.vibrate {
        after(triggerDelay, in: .userInitiated).then { (void) in
          AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
      }
    }
    if let attachments = attachments {
      content.attachments = attachments
    }
    if let category = category {
      content.categoryIdentifier = category.stringIdentifier
    }
    if let thread = thread {
      content.threadIdentifier = thread.stringIdentifier
    }
    
    content.userInfo = info
    
    return add(identifier: identifier, content: content)
  }
  
  public func add(identifier: StringIdentifiable,
                  content: UNNotificationContent) -> Promise<Void> {
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDelay, repeats: false)
    return add(identifier: identifier, content: content, trigger: trigger)
  }
  
  public func add(identifier: StringIdentifiable,
                  content: UNNotificationContent,
                  trigger: UNNotificationTrigger) -> Promise<Void> {
    let request = UNNotificationRequest(identifier: identifier.stringIdentifier,
                                        content: content,
                                        trigger: trigger)
    return notificationCenter.add(request: request)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: nil,
               userInfo: nil,
               attachments: nil,
               category: nil,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: nil,
               attachments: nil,
               category: nil,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  userInfo: [AnyHashable: Any]) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: nil,
               userInfo: userInfo,
               attachments: nil,
               category: nil,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  userInfo: [AnyHashable: Any]) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: userInfo,
               attachments: nil,
               category: nil,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  category: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: nil,
               attachments: nil,
               category: category,
               thread: nil)
  }
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  userInfo: [AnyHashable: Any],
                  category: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: nil,
               userInfo: userInfo,
               attachments: nil,
               category: category,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  userInfo: [AnyHashable: Any],
                  category: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: userInfo,
               attachments: nil,
               category: category,
               thread: nil)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: nil,
               attachments: nil,
               category: nil,
               thread: thread)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  userInfo: [AnyHashable: Any],
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: nil,
               userInfo: userInfo,
               attachments: nil,
               category: nil,
               thread: thread)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  userInfo: [AnyHashable: Any],
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: userInfo,
               attachments: nil,
               category: nil,
               thread: thread)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  category: StringIdentifiable,
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: nil,
               attachments: nil,
               category: category,
               thread: thread)
  }
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  userInfo: [AnyHashable: Any],
                  category: StringIdentifiable,
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: nil,
               userInfo: nil,
               attachments: nil,
               category: category,
               thread: thread)
  }
  
  public func add(identifier: StringIdentifiable,
                  title: StringIdentifiable,
                  body: StringIdentifiable,
                  alertStyle: AlertStyle,
                  userInfo: [AnyHashable: Any],
                  category: StringIdentifiable,
                  thread: StringIdentifiable) -> Promise<Void> {
    return add(identifier: identifier,
               title: title,
               subtitle: nil,
               body: body,
               badge: nil,
               alertStyle: alertStyle,
               userInfo: userInfo,
               attachments: nil,
               category: category,
               thread: thread)
  }
}

// Move to "BeamCoreKit"
func onBackgroundThreadDo(_ call: @escaping () -> Void) {
  DispatchQueue.global().async {
    call()
  }
}

// Move to "BeamPromiseKit"
func after(_ interval: TimeInterval, in context: Context = .main) -> Promise<Void> {
  return Promise<Void>(in: context) { fulfill, fail, _ in
    fulfill(())
    }.defer(in: context, 1.0)
}

