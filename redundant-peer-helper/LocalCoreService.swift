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
        
        let hasErr: (Error) -> () = { [weak queue] in
            queue?.cancel()

            cbk(.encounteredError($0))
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

// MARK: - Get Peer Info
extension LocalCoreService {
    /** Peer Info Data
     */
    struct PeerInfo {
        /** Connected peer
         */
        private struct Peer {}
        
        /** Peers represented in the peer info response
         */
        private let _peers: [Peer]
        
        /** Number of peers connected
         */
        var peerCount: Int { return _peers.count }
        
        /** Put together a peer info response from a raw JSON representation
         */
        init?(fromJsonArray: NSArray?) {
            guard let jsonArray = fromJsonArray else { return nil }
            
            _peers = jsonArray.map { _ in Peer() }
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
