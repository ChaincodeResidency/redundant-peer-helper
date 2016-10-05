//
//  RedundantPeer.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Redundant peer service
 */
class RedundantPeer: BlockchainDataSource {
    // MARK: - Properties
    
    /** Address
     */
    let address: String
    
    /** Determine when this node was first connected
     */
    let connectedSince: Date?
    
    /** Network type
    */
    let networkType = BlockchainDataNetworkType.redundantPeer
    
    /** Service type
     */
    let service: BlockchainDataService
    
    /** Service url
     */
    let serviceUrl: URL
    
    // MARK: - Init
    
    /** Create with an address
     */
    init?(withAddress: String) {
        guard let url = URL(string: withAddress) else { return nil }
        
        address = withAddress
        
        connectedSince = Date()
        
        service = .redundantPeer
        
        serviceUrl = url
    }
}

// MARK: - Errors

/** Request error
 */
enum RedundantPeerRequestError: Error {
    case chainMismatch
    case expectedLinkHeader
    case expectedRecoveryData
    case expectedSerializedBlocks
    case missingStatusCode
    case unexpectedStatusCode
}

// MARK: - Equatable
extension RedundantPeer: Equatable {}

/** Define equality between redundant peers by their URL
 */
func ==(lhs: RedundantPeer, rhs: RedundantPeer) -> Bool {
    return lhs.address == rhs.address
}

// MARK: - Hashable
extension RedundantPeer: Hashable {
    /** Unique value for the light node
     */
    var hashValue: Int { return address.hashValue }
}

// MARK: - Chain Mismatch Resolution
extension RedundantPeer {
    /** Get a recovery url from get newer blocks response data
     */
    fileprivate func _getRecoveryUrl(fromResponseData data: Data?, cbk: @escaping (_ err: Error?, _ url: URL?) -> ()) {
        let hasErr: (Error) -> () = { cbk($0, nil) }
        
        let reqErr: (RedundantPeerRequestError) -> () = { hasErr($0) }
        
        guard let recoveryData = data else { return reqErr(.expectedRecoveryData) }
        
        let recoveryJson: Any
        
        do {
            recoveryJson = try JSONSerialization.jsonObject(with: recoveryData, options: .allowFragments)
        }
        catch let err {
            return hasErr(err)
        }
        
        guard let hashes = ((recoveryJson as? [String: Any])?["error"] as? [String: Any])?["hashes"] as? [String] else {
            return reqErr(.expectedRecoveryData)
        }
        
        let blockHashes = hashes.map { BlockHash(forString: $0) }.flatMap { $0 }
        
        guard !blockHashes.isEmpty else { return reqErr(.expectedRecoveryData) }
        
        RedundantPeerRefresh.getRecoveryUrl(fromBlockHashes: blockHashes, forRedundantPeer: self) { err, url in
            if let err = err { return hasErr(err) }
            
            cbk(nil, url?.asUrl)
        }
    }
}

// MARK: - Getting Blocks
extension RedundantPeer {
    /** Pull newer blocks
     */
    func getNewerBlocks(
        fromUrl url: URL,
        cbk: @escaping (_ err: Error?, _ blocks: [HexSerializedBlock]?, _ continuation: URL?) -> ())
    {
        let gotBlocks: ([HexSerializedBlock]?, _ continuation: URL) -> () = { cbk(nil, $0, $1) }
        let hasErr: (Error?) -> () = { cbk($0, nil, nil) }
        
        let reqErr: (RedundantPeerRequestError) -> () = { hasErr($0) }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, err in
            if let err = err { hasErr(err) }
            
            guard let statusCode = HttpStatusCode(fromUrlResponse: response) else {
                return reqErr(.unexpectedStatusCode)
            }
            
            switch statusCode {
            // When there are no newer blocks, just retry later with the same URL
            case .noContent:
                gotBlocks(nil, url)
                
            // The requested block hash was unknown by the remote service because of a chain mismatch
            case .notFound:
                self?._getRecoveryUrl(fromResponseData: data) { err, url in
                    if let err = err { return hasErr(err) }
                    
                    guard let url = url else { return reqErr(.expectedRecoveryData) }
                    
                    gotBlocks(nil, url)
                }
                
            // New blocks were found
            case .ok:
                guard
                    let links = HttpLinks(fromUrlResponse: response),
                    let next = links.current ?? links.next,
                    let continuationUrl = URL(string: next, relativeTo: url)
                    else
                {
                    return reqErr(.expectedLinkHeader)
                }
                
                guard
                    let blocksData = data,
                    let blocksJson = try? JSONSerialization.jsonObject(with: blocksData, options: .allowFragments),
                    let blockStrings = blocksJson as? [String],
                    !blockStrings.isEmpty
                    else
                {
                    return reqErr(.expectedSerializedBlocks)
                }
                
                let blocks = blockStrings.map { HexSerializedBlock(forString: $0) }.flatMap { $0 }
                
                guard blocks.count == blockStrings.count else { return reqErr(.expectedSerializedBlocks) }
                
                gotBlocks(blocks, continuationUrl)
            }
        }
        
        task.resume()
    }
}
