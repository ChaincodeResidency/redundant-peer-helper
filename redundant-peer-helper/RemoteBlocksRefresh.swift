//
//  RemoteBlocksRefresh.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Refresh blocks
 */
struct RemoteBlocksRefresh {
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
        private static let _baseUrl = URL(string: "https://bitcoin-light-cache.herokuapp.com")
        
        /** Starting block hash to request blocks after
        */
        private let _bestBlockHash: BlockHash
        
        /** Page limit
        */
        private static let _defaultPageLimit = 5
        
        /** Max number of blocks to get in a refresh page
        */
        private let _resultPageLimit: Int
        
        /** Create a refresh url with a block hash
        */
        init(withHash: BlockHash) {
            _bestBlockHash = withHash

            _resultPageLimit = type(of: self)._defaultPageLimit
        }

        /** As URL format
        */
        var asUrl: URL? {
            let path = "/v0/blocks/after/" + _bestBlockHash.asString + "/?limit=" + String(_resultPageLimit)
            
            return URL(string: path, relativeTo: type(of: self)._baseUrl)
        }
    }
    
    /** Get a recovery url from block hashes to try
    */
    static func getRecoveryUrl(fromBlockHashes: [BlockHash], cbk: @escaping (_ err: Error?, _ url: RefreshUrl?) -> ()) {
        let queue = TaskQueue()

        let hasErr: (Error) -> () = { [weak queue] in queue?.cancel(); cbk($0, nil) }
        let gotUrl: (RefreshUrl) -> () = { [weak queue] in queue?.cancel(); cbk(nil, $0) }
        
        fromBlockHashes.reversed().forEach { hash in
            queue.tasks += { _, go_on in
                LocalCoreRequest(method: .getHexSerializedBlock(hash: hash))?.execute { err, data in
                    if let err = err { return hasErr(err) }

                    guard let _ = data else { return go_on(nil) }
                    
                    gotUrl(RefreshUrl(withHash: hash))
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
    static func importBlocks(fromUrl url: URL?, cbk: @escaping (Error?, _ continuationUrl: URL?) -> ()) {
        let queue = TaskQueue()
        
        let hasErr: (Error?) -> () = { [weak queue] err in queue?.cancel(); cbk(err, nil) }

        var continuationUrl: URL?
        
        // Figure out which url to refresh from
        queue.tasks += { _, go_on in
            if let url = url { return go_on(url) }
            
            LocalCoreRequest(method: .getBestBlockHash)?.execute { err, bestBlockHashData in
                if let err = err { return hasErr(err) }

                guard let bestBlockHash = BlockHash(forString: bestBlockHashData as? String) else {
                    return hasErr(RefreshError.expectedBestBlockHash)
                }
                
                go_on(RefreshUrl(withHash: bestBlockHash).asUrl)
            }
        }

        // Pull in newer blocks
        queue.tasks += { url, go_on in
            guard let url = url as? URL else { return hasErr(RefreshError.expectedRefreshUrl) }
            
            RemoteBlockchainService.getNewerBlocks(fromUrl: url) { err, newerBlocks, in_continuationUrl in
                if let err = err { return hasErr(err) }
                
                continuationUrl = in_continuationUrl

                go_on(newerBlocks)
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
