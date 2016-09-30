//
//  TestGetHexSerializedBlock.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import XCTest

class TestGetHexSerializedBlock: XCTestCase {
    /** Block hash to use when testing get block
    */
    var blockHash: String?
    
    /** Get a sample block hash to use when testing get block
    */
    override func setUp() {
        super.setUp()
        
        let setupExpectation = expectation(description: "Populate blockhash")
        
        let cbk: (Any?) -> () = { self.blockHash = $0 as? String; setupExpectation.fulfill() }
        
        LocalCoreRequest(method: .getBestBlockHash)?.execute { return cbk($1) }

        waitForExpectations(timeout: NSTimeIntervalSince1970, handler: nil)
    }
    
    /** Test getting a hex serialized block
    */
    func testGetHexSerializedBlock() {
        guard let hash = blockHash else { return XCTFail("Expected best block hash") }
        
        guard let blockHash = BlockHash(forString: hash) else { return XCTFail("Expected block hash") }
        
        LocalCoreRequest(method: .getHexSerializedBlock(hash: blockHash))?.execute { err, blockData in
            if let _ = err { XCTFail("Expected no error from get block") }

            guard let serializedBlock = blockData as? String, !serializedBlock.isEmpty else {
                return XCTFail("Expected non empty block data")
            }
        }
    }
}
