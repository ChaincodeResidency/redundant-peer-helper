//
//  BlockchainDataSource.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

enum BlockchainDataNetworkType {
    case bitcoinNetwork, redundantPeer
}

/** Provider of blockchain data
 */
protocol BlockchainDataSource {
    var address: String { get }
    var connectedSince: Date? { get }
    var networkType: BlockchainDataNetworkType { get }
    var service: BlockchainDataService { get }
}
