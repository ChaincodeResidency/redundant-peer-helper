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
enum BlockchainDataService: Equatable {
    // MARK: - Cases
    
    /** Identified Bitcoin Core node
     */
    case bitcoinCore(minorVersion: Int, patchVersion: Int?)
    
    /** Bitcoin Knots node
     */
    case bitcoinKnots(minorVersion: Int, patchVersion: Int?)
    
    /** Redundant blockchain data service
     */
    case redundantPeer
    
    /** Unknown Bitcoin network peer
     */
    case unidentifiedBitcoinNetworkPeer(agent: String)

    // MARK: - Init
    
    /** Create from json
     */
    init(fromUserAgentString: String) {
        switch fromUserAgentString {
        case "/Satoshi:0.8.6/":
            self = type(of: self).bitcoinCore(minorVersion: 8, patchVersion: 6)
            
        case "/Satoshi:0.9.1/":
            self = type(of: self).bitcoinCore(minorVersion: 9, patchVersion: 1)
            
        case "/Satoshi:0.9.2/":
            self = type(of: self).bitcoinCore(minorVersion: 9, patchVersion: 2)

        case "/Satoshi:0.9.4/":
            self = type(of: self).bitcoinCore(minorVersion: 9, patchVersion: 4)
            
        case "/Satoshi:0.10.0/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 0)
            
        case "/Satoshi:0.10.1/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 1)
            
        case "/Satoshi:0.10.2/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 2)

        case "/Satoshi:0.10.4/":
            self = type(of: self).bitcoinCore(minorVersion: 10, patchVersion: 4)
            
        case "/Satoshi:0.11.0/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 0)
            
        case "/Satoshi:0.11.1/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 1)
            
        case "/Satoshi:0.11.2/", "/Satoshi:0.11.2(bitcore)/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: 2)
            
        case "/Satoshi:0.11.99/":
            self = type(of: self).bitcoinCore(minorVersion: 11, patchVersion: nil)
            
        case "/Satoshi:0.12.0/":
            self = type(of: self).bitcoinCore(minorVersion: 12, patchVersion: 0)
            
        case "/Satoshi:0.12.1/", "/Satoshi:0.12.1(bitcore)/":
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

/** Define equatability between services
 */
func ==(lhs: BlockchainDataService, rhs: BlockchainDataService) -> Bool {
    switch (lhs, rhs) {
    case (.bitcoinCore(let lhsMinorVer, let lhsPatchVer), .bitcoinCore(let rhsMinorVer, let rhsPatchVer)),
         (.bitcoinKnots(let lhsMinorVer, let lhsPatchVer), .bitcoinKnots(let rhsMinorVer, let rhsPatchVer)):
        return lhsMinorVer == rhsMinorVer && lhsPatchVer == rhsPatchVer

    case (.redundantPeer, .redundantPeer):
        return true
        
    case (.unidentifiedBitcoinNetworkPeer(let lhsAgent), .unidentifiedBitcoinNetworkPeer(let rhsAgent)):
        return lhsAgent == rhsAgent
        
    default:
        return false
    }
}
