//
//  RemovePeerViewController.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/3/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Cocoa

extension NSViewController {
    /** Dismiss with error
    */
    func dismiss(_ sender: Any?, withError: Error) {
        log(err: withError)
        
        dismiss(sender)
    }
}

/** View controller for removing a peer
*/
class RemovePeerViewController: NSViewController {
    // MARK: - @IBActions
    
    /** Execute removal
    */
    @IBAction func removePeer(_ sender: NSButton) {
        guard let peer = peer else { return dismiss(sender, withError: RemovePeerError.expectedPeer) }
        
        confirmPeerRemoval?(peer)
        
        dismiss(sender)
    }
    
    // MARK: - @IBOutlets
    
    /** Title label
    */
    @IBOutlet weak var titleTextField: NSTextField?
    
    // MARK: - Properties (View Controller Configuration)
    
    /** Confirm removal
     
        FIXME: - this should be contextual with the "ban" checkbox
    */
    var confirmPeerRemoval: ((BlockchainDataSource) -> ())?
    
    /** Peer to remove
    */
    var peer: BlockchainDataSource?
    
    // MARK: - Errors
    
    /** Errors
    */
    enum RemovePeerError: Error {
        case expectedPeer
    }
    
    // MARK: - NSViewController
    
    /** View loaded
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        let peerTitle = URL(string: (peer?.address ?? String()))?.host ?? String()
        let locale = Locale.current as NSLocale
        
        let closeQuote = (locale.object(forKey: NSLocale.Key.quotationEndDelimiterKey) as? String) ?? "\""
        let openQuote = (locale.object(forKey: NSLocale.Key.quotationBeginDelimiterKey) as? String) ?? "\""

        titleTextField?.stringValue = "Remove Blockchain sync source " + openQuote + peerTitle + closeQuote + "?"
    }
}
