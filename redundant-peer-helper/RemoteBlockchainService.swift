//
//  RedundantPeerRequest.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Remote Blockchain Service
 */
struct RemoteBlockchainService {
    // MARK: - Chain Mismatch
    
    /** Get a recovery url from get newer blocks response data
     */
    private static func _getRecoveryUrl(
        fromResponseData data: Data?,
        cbk: @escaping (_ err: Error?, _ url: URL?) -> ())
    {
        let reqErr: (RequestError) -> () = { cbk($0, nil) }
        
        guard let recoveryData = data else { return reqErr(.expectedRecoveryData) }
        
        let recoveryJson: Any
        
        do {
            recoveryJson = try JSONSerialization.jsonObject(with: recoveryData, options: .allowFragments)
        }
        catch let err {
            return cbk(err, nil)
        }
        
        guard let hashes = ((recoveryJson as? [String: Any])?["error"] as? [String: Any])?["hashes"] as? [String] else {
            return reqErr(.expectedRecoveryData)
        }
        
        let blockHashes = hashes.map { BlockHash(forString: $0) }.flatMap { $0 }
        
        guard !blockHashes.isEmpty else { return reqErr(.expectedRecoveryData) }
        
        RemoteBlocksRefresh.getRecoveryUrl(fromBlockHashes: blockHashes) { err, url in
            if let err = err { return cbk(err, nil) }
            
            cbk(nil, url?.asUrl)
        }
    }
    
    // MARK: - Errors

    /** Request error
     */
    enum RequestError: Error {
        case chainMismatch
        case expectedLinkHeader
        case expectedRecoveryData
        case expectedSerializedBlocks
        case missingStatusCode
        case unexpectedStatusCode
    }
    
    // MARK: - Refreshing
    
    /** Execute request
     */
    static func getNewerBlocks(
        fromUrl url: URL,
        cbk: @escaping (_ err: Error?, _ blocks: [HexSerializedBlock]?, _ continuation: URL?) -> ())
    {
        let gotBlocks: ([HexSerializedBlock]?, _ continuation: URL) -> () = { cbk(nil, $0, $1) }
        let hasErr: (Error?) -> () = { cbk($0, nil, nil) }
        let reqErr: (RequestError) -> () = { hasErr($0) }
        
        let task = URLSession.shared.dataTask(with: url) { responseData, response, err in
            if let err = err { hasErr(err) }
            
            guard let statusCode = HttpStatusCode(fromUrlResponse: response) else {
                return reqErr(.unexpectedStatusCode)
            }
            
            switch statusCode {
            case .noContent:
                return gotBlocks(nil, url)
                
            case .notFound:
                return RemoteBlockchainService._getRecoveryUrl(fromResponseData: responseData) { err, url in
                    if let err = err { return hasErr(err) }
                    
                    guard let url = url else { return reqErr(.expectedRecoveryData) }
                    
                    gotBlocks(nil, url)
                }
                
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
                    let blocksData = responseData,
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
