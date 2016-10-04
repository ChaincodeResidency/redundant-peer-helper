//
//  RedundantPeerRefresh.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Refresh blocks
 */
struct RedundantPeerRefresh {
    // MARK: - Errors
    
    /** Block refresh operation error
    */
    enum RefreshError: Error {
        case expectedBestBlockHash
        case expectedMatchingBlockHash
        case expectedRefreshUrl
        case unexpectedRemoteServiceResponse
    }

    // MARK: - Service URL
    
    /** Url to retrieve new blocks from
    */
    struct RefreshUrl {
        /** Service Url
        */
        private let _baseUrl: URL
        
        /** Starting block hash to request blocks after
        */
        private let _bestBlockHash: BlockHash
        
        /** Create a refresh url with a block hash
        */
        init(withHash: BlockHash, baseUrl: URL) {
            _baseUrl = baseUrl
            
            _bestBlockHash = withHash
        }

        /** As URL format
        */
        var asUrl: URL? {
            let path = "/v0/blocks/after/" + _bestBlockHash.asString + "/"
            
            return URL(string: path, relativeTo: _baseUrl)
        }
    }
    
    /** Get a recovery url from block hashes to try
    */
    static func getRecoveryUrl(
        fromBlockHashes: [BlockHash],
        forRedundantPeer: RedundantPeer,
        cbk: @escaping (_ err: Error?, _ url: RefreshUrl?) -> ())
    {
        let queue = TaskQueue()

        let hasErr: (Error) -> () = { [weak queue] in queue?.cancel(); cbk($0, nil) }
        let gotUrl: (RefreshUrl) -> () = { [weak queue] in queue?.cancel(); cbk(nil, $0) }
        
        fromBlockHashes.reversed().forEach { hash in
            queue.tasks += { _, go_on in
                LocalCoreRequest(method: .getHexSerializedBlock(hash: hash))?.execute { err, data in
                    if let err = err { return hasErr(err) }

                    guard let _ = data else { return go_on(nil) }
                    
                    gotUrl(RefreshUrl(withHash: hash, baseUrl: forRedundantPeer.serviceUrl))
                }
            }
        }
        
        queue.run {
            cbk(nil, nil)
        }
    }
    
    // MARK: - Make Request
    
    /** Execute refresh
    */
    static func importBlocks(
        fromUrl url: URL?,
        redundantPeer peer: RedundantPeer,
        cbk: @escaping (Error?, _ continuationUrl: URL?) -> ())
    {
        let queue = TaskQueue()
        
        let hasErr: (Error?) -> () = { [weak queue] err in queue?.cancel(); cbk(err, nil) }

        let hasRefreshErr: (RefreshError) -> () = { hasErr($0) }
        
        var continuationUrl: URL?
        
        // Figure out which url to refresh from
        queue.tasks += { _, go_on in
            if let url = url { return go_on(url) }
            
            LocalCoreRequest(method: .getBestBlockHash)?.execute { err, bestBlockHashData in
                if let err = err { return hasErr(err) }

                guard let bestBlockHash = BlockHash(forString: bestBlockHashData as? String) else {
                    return hasRefreshErr(.expectedBestBlockHash)
                }
                
                go_on(RefreshUrl(withHash: bestBlockHash, baseUrl: url ?? peer.serviceUrl).asUrl)
            }
        }

        // Pull in newer blocks
        queue.tasks += { url, go_on in
            guard let url = url as? URL else { return hasRefreshErr(.expectedRefreshUrl) }
            
            peer.getNewerBlocks(fromUrl: url) { err, blocks, url in
                if let err = err { return hasErr(err) }
                
                continuationUrl = url

                go_on(blocks)
            }
        }
        
        // Import newer blocks
        queue.tasks += { newerBlocks, go_on in
            guard let newerBlocks = newerBlocks as? [HexSerializedBlock] else { return go_on(nil) }

            LocalCoreService.consume(hexSerializedBlocks: newerBlocks) { result in
                switch result {
                case .completedSuccessfully:
                    go_on(nil)
                    
                case .encounteredError(let err):
                    hasErr(err)
                }
            }
        }
        
        // Execute queue and return continuation for the next refresh
        queue.run {
            cbk(nil, continuationUrl)
        }
    }
}
