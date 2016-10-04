//
//  AppStatusBarItem.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/26/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Cocoa

/** Protocol for app status bar item
 */
protocol AppStatusBarItemDelegate {
    /** Pressed exit button
    */
    func appStatusBarRequestedApplicationExit()
}

/** Status bar item for the App
 */
class AppStatusBarItem: NSObject {
    // MARK: - Properties (Configuration)
    
    /** Delegate for app status bar actions
    */
    var delegate: AppStatusBarItemDelegate?
    
    // MARK: - Properties (Private)

    /** Connections menu item
    */
    fileprivate let _connectionsMenuItem: NSMenuItem
    
    /** Menu item - needs to be retained here so that it stays around
    */
    private let _statusBarItem: NSStatusItem

    /** Menu for status bar item
    */
    fileprivate let _statusBarMenu: NSMenu
    
    /** Icon image for app status bar
     */
    private static let _toolbarIconImage = NSImage(named: "rp-toolbar-icon")
    
    // MARK: - Selectors

    /** Quit the application (Selector)
    */
    func exitApplication(_ sender: NSMenuItem) {
        delegate?.appStatusBarRequestedApplicationExit()
    }

    // MARK: - Init
    
    /** Setup the bar item
    */
    override init() {
        _statusBarItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

        _statusBarItem.image = type(of: self)._toolbarIconImage

        _statusBarMenu = NSMenu()
        
        _statusBarItem.menu = _statusBarMenu
        
        _connectionsMenuItem = _statusBarMenu.addItem(
            withTitle: "Determining number of network connections...",
            action: nil,
            keyEquivalent: String()
        )

        _statusBarMenu.addItem(.separator())
        
        let quitItem = _statusBarMenu.addItem(
            withTitle: "Quit Bitcoin Core Helper",
            action: #selector(exitApplication(_:)),
            keyEquivalent: String()
        )
        
        super.init()
        
        _statusBarMenu.delegate = self
        
        quitItem.target = self
    }
}

// MARK: - NSMenuDelegate
extension AppStatusBarItem: NSMenuDelegate {
    private func _peerCountDisplayString(forCount: Int) -> String {
        let template = "%@ connections to the Bitcoin network."
        
        let numberFormatter = NumberFormatter()
        
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .none
        
        let displayNumber = numberFormatter.string(from: NSNumber(value: forCount)) ?? String()
        
        return NSString(format: NSLocalizedString(template, comment: String()) as NSString, displayNumber) as String
    }
    
    /** Update the peer info item
    */
    private func _updatePeerCount() {
        LocalCoreService.getPeerInfo { [weak self] peerInfoResponse in
            switch peerInfoResponse {
            case .encounteredError(let err):
                log(err: err)
                
            case .receivedPeerInfo(let peerInfo):
                guard let peerCount = self?._peerCountDisplayString(forCount: peerInfo.peers.count) else { break }
                
                self?._connectionsMenuItem.title = peerCount
            }
        }
    }
    
    /** A status bar item menu needs updating
    */
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == _statusBarMenu else { return print("Expected status bar menu") }

        _updatePeerCount()
    }
}
