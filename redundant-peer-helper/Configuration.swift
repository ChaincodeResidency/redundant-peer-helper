//
//  Configuration.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Configuration data
 */
class Configuration {
    // MARK: - User Defaults
    
    /** Standard user defaults
    */
    private enum StandardUserDefaults: String {
        case redundantPeers = "redundant_peers"
        
        /** Get default as key
        */
        var asKey: String { return rawValue }

        /** Set value
        */
        func set(value: Any?) {
            UserDefaults.standard.set(value, forKey: asKey)

            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Saved Redundant Peer Addresses
    
    /** Stored redundant peer addresses
     */
    private class var _savedRedundantPeerAddresses: Set<String> {
        return Set(savedRedundantPeers.map { $0.address })
    }
    
    /** Add a redundant peer to saved peers set
    */
    class func add(savedRedundantPeer peer: RedundantPeer) {
        let addresses: Any? = Array(_savedRedundantPeerAddresses.union([peer.address]))
        
        StandardUserDefaults.redundantPeers.set(value: addresses)
    }
    
    /** Remove a redundant peer from the saved peers set
    */
    class func remove(savedRedundantPeer peer: RedundantPeer) {
        let addresses: Any? = Array(_savedRedundantPeerAddresses.subtracting([peer.address]))

        StandardUserDefaults.redundantPeers.set(value: addresses)
    }
    
    /** Stored redundant peers
    */
    class var savedRedundantPeers: [RedundantPeer] {
        return (UserDefaults.standard.stringArray(forKey: StandardUserDefaults.redundantPeers.asKey) ?? [])
            .map { RedundantPeer(withAddress: $0) }
            .flatMap { $0 }
    }
}
