//
//  TestGetBlockchainInfo.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import XCTest

/** Test getting blockchain info
 */
class TestGetBlockchainInfo: XCTestCase {
    /** Execute test of get blockchain info
    */
    func testGetBlockchainInfo() {
        LocalCoreRequest(method: .getBlockchainInfo)?.execute { err, blockchainInfoData in
            if let _ = err { XCTFail("Expected no error") }
            
            guard
                let blockchainInfoDictionary = blockchainInfoData as? NSDictionary,
                let blockchainInfo = LocalCoreResponses.BlockchainInfo(fromJsonDictionary: blockchainInfoDictionary),
                blockchainInfo.currentHeight > Int()
            else
            {
                return XCTFail("Expected blockchain info")
            }
        }
    }
}
