//
//  TestGetBlockHash.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import XCTest

/** Test get block hash for a height
*/
class TestGetBlockHash: XCTestCase {
    /** Test block height to retrieve hash for
    */
    var blockchainInfo: LocalCoreResponses.BlockchainInfo?

    /** Block hash that should be returned
    */
    var targetBlockHash: String?
    
    /** Retrieve a block height to get a hash for
    */
    override func setUp() {
        super.setUp()
        
        let asyncPromise = expectation(description: "Got blockchain info")
        
        LocalCoreRequest(method: .getBlockchainInfo)?.execute { err, blockchainInfoData in
            guard err == nil else { return XCTFail("Expected no errors") }
            
            guard
                let blockchainInfoDictionary = blockchainInfoData as? NSDictionary,
                let blockchainInfo = LocalCoreResponses.BlockchainInfo(fromJsonDictionary: blockchainInfoDictionary)
                else
            {
                return XCTFail("Expected blockchain info")
            }
            
            self.blockchainInfo = blockchainInfo
            
            asyncPromise.fulfill()
        }
        
        waitForExpectations(timeout: NSTimeIntervalSince1970, handler: nil)
    }
    
    /** Retrieve a block hash for a height
    */
    func testGetBlockHash() {
        guard
            let height = blockchainInfo?.currentHeight,
            let targetHash = blockchainInfo?.bestBlockHash
            else
        {
            return XCTFail("Expected current height")
        }
        
        LocalCoreRequest(method: .getBlockHash(forHeight: height))?.execute { err, hash in
            guard err == nil else { return XCTFail("Expected no error") }

            guard let hash = hash as? String else { return XCTFail("Expected hash string") }
            
            XCTAssertEqual(hash, targetHash)
        }
    }
}
