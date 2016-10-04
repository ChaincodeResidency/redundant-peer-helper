//
//  RedundantPeerPollWorker.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/29/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Refresh from remote blockchain data
 
 FIXME: - exponential timer backoff when errors of failures are encountered
 */
class RedundantPeerPollWorker {
    /** Block refresh continuation url
     */
    lazy private var _blockRefreshUrls: [RedundantPeer: URL] = [:]
    
    /** Number of seconds to wait before polling
    */
    private static let _pollFrequencySeconds: TimeInterval = 60

    /** Run a block refresh
     */
    @objc func refreshBlocks() {
        Configuration.savedRedundantPeers.forEach(_refreshAndImportBlocks)
    }

    /** Trigger a pull from a redundant peer
    */
    private func _refreshAndImportBlocks(fromRedundantPeer peer: RedundantPeer) {
        let url = _blockRefreshUrls[peer] ?? nil
        
        RedundantPeerRefresh.importBlocks(fromUrl: url, redundantPeer: peer) { [weak self] err, continuationUrl in
            if let err = err { return log(err: err) }

            guard let continuationUrl = continuationUrl else { return }

            self?._blockRefreshUrls[peer] = continuationUrl
        }
    }

    /** Begin refreshing
    */
    func start() {
        refreshBlocks()
        
        Timer.scheduledTimer(
            timeInterval: type(of: self)._pollFrequencySeconds,
            target: self,
            selector: #selector(refreshBlocks),
            userInfo: nil,
            repeats: true
        )
    }
}
