//
//  BlockchainDataService.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Service types
 */
enum BlockchainDataService {
    // MARK: - Cases
    
    /** Identified Bitcoin Core node
     */
    case bitcoinCore(minorVersion: Int, patchVersion: Int?)
    
    /** Bitcoin Knots node
     */
    case bitcoinKnots(minorVersion: Int, patchVersion: Int)
    
    /** Redundant blockchain data service
     */
    case redundantPeer
    
    /** Unknown Bitcoin network peer
     */
    case unidentifiedBitcoinNetworkPeer(agent: String)
    
    // MARK: - Computed Properties
    
    /** Determine if this source is from the Bitcoin Network
    */
    var isFromBitcoinNetwork: Bool {
        switch self {
        case .bitcoinCore(minorVersion: _, patchVersion: _),
             .bitcoinKnots(minorVersion: _, patchVersion: _),
             .unidentifiedBitcoinNetworkPeer(agent: _):
            return true

        case .redundantPeer:
            return false
        }
    }

    // MARK: - Init
    
    /** Create from json
     */
    init(fromUserAgentString: String) {
        switch fromUserAgentString {
        case "/Satoshi:0.8.6/":
            self = type(of: self).bitcoinCore(minorVersion: 8, patchVersion: 6)

        case "/Satoshi:0.9.4/":
            self = type(of: self).bitcoinCore(minorVersion: 9, patchVersion: 4)
            
        case "/Satoshi:0.10.2/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 2)

        case "/Satoshi:0.10.4/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 4)
            
        case "/Satoshi:0.11.0/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 0)
            
        case "/Satoshi:0.11.1/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 1)
            
        case "/Satoshi:0.11.2/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 2)
            
        case "/Satoshi:0.11.99/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: nil)
            
        case "/Satoshi:0.12.0/":
            self = type(of: self).bitcoinCore(minorVersion: 12, patchVersion: 0)
            
        case "/Satoshi:0.12.1/":
            self = type(of: self).bitcoinCore(minorVersion: 12, patchVersion: 1)
            
        case "/Satoshi:0.12.1/Knots:20160629/":
            self = type(of: self).bitcoinKnots(minorVersion: 12, patchVersion: 1)
            
        case "/Satoshi:0.12.99/":
            self = type(of: self).bitcoinCore(minorVersion: 12, patchVersion: nil)
            
        case "/Satoshi:0.13.0/":
            self = type(of: self).bitcoinCore(minorVersion: 13, patchVersion: 0)
            
        case "/Satoshi:0.13.99/":
            self = type(of: self).bitcoinCore(minorVersion: 13, patchVersion: nil)

        default:
            self = type(of: self).unidentifiedBitcoinNetworkPeer(agent: fromUserAgentString)
        }
    }
}
