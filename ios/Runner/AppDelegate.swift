import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller=window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name:"nido/reminders",binaryMessenger:controller.binaryMessenger).setMethodCallHandler { call,result in
        let args=call.arguments as? [String:Any] ?? [:]
        let center=UNUserNotificationCenter.current(),prefs=UserDefaults.standard
        if call.method=="configure" {
          let daily=args["daily"] as? Bool ?? false,moods=args["moods"] as? Bool ?? false
          prefs.set(moods,forKey:"nidoMoodAlerts")
          center.removePendingNotificationRequests(withIdentifiers:(1...7).map{"nido-care-\($0)"})
          if daily {
            let activities=["Compartan una foto de su día.","¿Una pequeña partida juntos?","Pregúntale qué fue lo mejor de su día.","Planeen un lugar para visitar.","Guarden un recuerdo en su álbum.","Dibujen algo juntos.","Envíale unas palabras bonitas."]
            for weekday in 1...7 {
              let content=UNMutableNotificationContent();content.title="Un ratito para ustedes ♥";content.body=activities[weekday-1];content.sound = .default
              var date=DateComponents();date.weekday=weekday;date.hour=args["hour"] as? Int ?? 19;date.minute=args["minute"] as? Int ?? 0
              center.add(UNNotificationRequest(identifier:"nido-care-\(weekday)",content:content,trigger:UNCalendarNotificationTrigger(dateMatching:date,repeats:true)))
            }
          }
          result(true)
        } else if call.method=="mood" {
          let stamp=args["updated_at"] as? String ?? "",previous=prefs.string(forKey:"nidoMoodAt") ?? ""
          prefs.set(stamp,forKey:"nidoMoodAt")
          if prefs.bool(forKey:"nidoMoodAlerts") && !stamp.isEmpty && !previous.isEmpty && stamp != previous {
            let content=UNMutableNotificationContent();content.title="Un momento para acompañarse";content.body="Tu pareja compartió cómo se siente. Entra a NIDO para acompañarle.";content.sound = .default
            center.add(UNNotificationRequest(identifier:"nido-mood",content:content,trigger:UNTimeIntervalNotificationTrigger(timeInterval:1,repeats:false)))
          }
          result(true)
        } else {result(FlutterMethodNotImplemented)}
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
