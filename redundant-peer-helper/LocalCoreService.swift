//
//  LocalCoreService.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/30/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

// MARK: - Results

/** Local Core Service
 */
struct LocalCoreService {
    // MARK: - Errors
    
    /** Core Service Errors
    */
    enum CoreServiceError: Error {
        case malformedResponse
    }
    
    // MARK: - Request Results
    
    /** Core Service Request Results
    */
    enum ServiceResult {
        case encounteredError(Error)
        case completedSuccessfully
    }
}

// MARK: - Consume blocks
extension LocalCoreService {
    /** Push hex serialized blocks into the local Core instance
     */
    static func consume(hexSerializedBlocks: [HexSerializedBlock], cbk: @escaping (ServiceResult) -> ()) {
        let queue = TaskQueue()
        
        let hasErr: (Error) -> () = { [weak queue] err in
            queue?.cancel()

            cbk(.encounteredError(err))
        }
        
        hexSerializedBlocks.forEach { block in
            queue.tasks += { _, go_on in
                LocalCoreRequest(method: .importBlock(hexSerializedBlock: block))?.execute { err, _ in
                    if let err = err { return hasErr(err) }
                    
                    go_on(nil)
                }
            }
        }
        
        queue.run {
            cbk(.completedSuccessfully)
        }
    }
}

// MARK: - Get Blockchain Info
extension LocalCoreService {
    /** Response from get blockchain info
     */
    struct BlockchainInfo {
        /** Current best block hash
         */
        let bestBlockHash: String
        
        /** Current best blockchain height
         */
        let currentHeight: Int
        
        /** Pruned height if applicable
         */
        let pruneHeight: Int?
        
        /** Create with properties
         */
        init(bestBlockHash: String, currentHeight: Int, pruneHeight: Int?) {
            self.bestBlockHash = bestBlockHash
            self.currentHeight = currentHeight
            self.pruneHeight = pruneHeight
        }
        
        /** Put together a blockchain info response from a raw JSON representation
         */
        init?(fromJsonDictionary: NSDictionary?) {
            guard
                let jsonDict = fromJsonDictionary,
                let currentHeight = jsonDict["blocks"] as? NSNumber,
                let bestBlockHash = jsonDict["bestblockhash"] as? NSString
                else
            {
                return nil
            }
            
            self = type(of: self).init(
                bestBlockHash: bestBlockHash as String,
                currentHeight: currentHeight.intValue,
                pruneHeight: (jsonDict["pruneheight"] as? NSNumber)?.intValue
            )
        }
    }
}

// MARK: - Get Peer Info
extension LocalCoreService {
    /** Peer Info Data
     */
    struct PeerInfo {
        /** Connected peer
         */
        struct Peer: BlockchainDataSource {
            /** Address
            */
            let address: String
            
            /** Determine when this node was first connected
            */
            let connectedSince: Date?
            
            /** Service type
            */
            let service: BlockchainDataService
            
            /** Create from JSON data
            */
            init(fromJson: [String: Any]?) {
                service = BlockchainDataService(fromUserAgentString: fromJson?["subver"] as? String ?? String())

                address = "bitcoin://" + (fromJson?["addr"] as? String ?? "unknown")
                
                if let firstConnected = (fromJson?["conntime"] as? NSNumber)?.doubleValue {
                    connectedSince = Date(timeIntervalSince1970: firstConnected)
                } else {
                    connectedSince = nil
                }
            }
        }
        
        /** Peers represented in the peer info response
         */
        let peers: [Peer]
        
        /** Put together a peer info response from a raw JSON representation
         */
        init?(fromJsonArray: NSArray?) {
            guard let jsonArray = fromJsonArray else { return nil }
            
            peers = jsonArray.map { return Peer(fromJson: $0 as? [String: Any]) }
        }
    }

    /** Responses from get peer info
    */
    enum PeerInfoResponse {
        case encounteredError(Error)
        case receivedPeerInfo(PeerInfo)
    }

    /** Get peer info
    */
    static func getPeerInfo(cbk: @escaping (PeerInfoResponse) -> ()) {
        LocalCoreRequest(method: .getPeerInfo)?.execute() { err, peerData in
            DispatchQueue.main.async {
                if let err = err { return cbk(PeerInfoResponse.encounteredError(err)) }
                
                guard let peerInfo = PeerInfo(fromJsonArray: peerData as? NSArray) else {
                    return cbk(PeerInfoResponse.encounteredError(CoreServiceError.malformedResponse))
                }
                
                return cbk(PeerInfoResponse.receivedPeerInfo(peerInfo))
            }
        }
    }
}
