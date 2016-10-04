//
//  AppDelegate.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/26/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Cocoa

/** Main application
 */
@NSApplicationMain
class AppDelegate: NSObject {
    /** Application status bar item
    */
    lazy fileprivate var _appStatusBarItem: AppStatusBarItem? = AppStatusBarItem()

    /** Blockchain refreshing worker
    */
    lazy fileprivate var _redundantPeerPollWorker: RedundantPeerPollWorker? = RedundantPeerPollWorker()
}

// MARK: - NSApplicationDelegate
extension AppDelegate: NSApplicationDelegate {
    /** The application is done launching, first chance to initialize the application
    */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _appStatusBarItem?.delegate = self
        
        _redundantPeerPollWorker?.start()
  
        NSApplication.shared().windows.first?.title = "RedundantPeer"
    }
}

// MARK: - AppStatusBarItemDelegate
extension AppDelegate: AppStatusBarItemDelegate {
    /** Exit the application
    */
    func appStatusBarRequestedApplicationExit() {
        NSApplication.shared().terminate(self)
    }
}
