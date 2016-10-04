//
//  AddPeerViewController.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/3/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Cocoa

/** View controller for adding a peer
*/
class AddPeerViewController: NSViewController {
    // MARK: - @IBActions
    
    /** Pressed add peer
    */
    @IBAction func addPeer(_ sender: NSButton) {
        guard let address = peerAddress?.stringValue, let peer = RedundantPeer(withAddress: address) else {
            return dismiss(sender, withError: AddPeerError.expectedPeerAddress)
        }
        
        addPeer?(peer)

        dismiss(sender)
    }

    // MARK: - @IBOutlets
    
    /** Peer address text entry field
    */
    @IBOutlet weak var peerAddress: NSTextField?
    
    // MARK: - Errors

    /** Add Peer Errors
    */
    enum AddPeerError: Error {
        case expectedPeerAddress
    }
    
    // MARK: - Properties (View Controller Configuration)
    
    /** Add peer callback
    */
    var addPeer: ((RedundantPeer) -> ())?
}
