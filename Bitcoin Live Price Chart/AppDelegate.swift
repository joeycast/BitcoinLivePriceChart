// AppDelegate.swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    // Called when the application has finished launching
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Disable the idle timer to prevent the screensaver from activating
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }
    
    // Called when the application is about to terminate
    func applicationWillTerminate(_ application: UIApplication) {
        // Re-enable the idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // Called when the application enters the background
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Re-enable the idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // Called when the application will enter the foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Disable the idle timer again
        UIApplication.shared.isIdleTimerDisabled = true
    }
}