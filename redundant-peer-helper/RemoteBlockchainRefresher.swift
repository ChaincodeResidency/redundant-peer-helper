//
//  RemoteBlockchainRefresher.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/29/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Refresh from remote blockchains
 
 FIXME: - exponential timer backoff when errors of failures are encountered
 */
class RemoteBlockchainRefresher {
    /** Block refresh continuation url
     */
    private var _blockRefreshUrl: URL?
    
    /** Number of seconds to wait before polling
    */
    private static let _pollFrequencySeconds: TimeInterval = 60

    /** Run a block refresh
     */
    @objc func refreshBlocks() {
        RemoteBlocksRefresh.importBlocks(fromUrl: _blockRefreshUrl) { [weak self] err, continuationUrl in
            if let err = err { return log(err: err) }
            
            self?._blockRefreshUrl = continuationUrl
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
