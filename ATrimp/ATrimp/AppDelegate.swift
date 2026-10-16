//
//  AppDelegate.swift
//  ATrimp
//
//
import IQKeyboardManagerSwift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let keyboard = IQKeyboardManager.shared
        keyboard.isEnabled = true
        keyboard.resignOnTouchOutside = true
        keyboard.keyboardDistance = 28
        keyboard.enableAutoToolbar = false

        Task { await ATStoreKit.shared.loadProducts() }

        ATNotifications.checkForFilingsAtNotedPlaces()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
