//
//  TestGetBestBlockHash.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import XCTest

class TestGetBestBlockHash: XCTestCase {
    func testGetBestBlockHash() {
        LocalCoreRequest(method: .getBestBlockHash)?.execute { err, hashData in
            if let _ = err { return XCTFail("Expected no error") }
            
            guard let hash = hashData as? String, !hash.isEmpty else { return XCTFail("Expected best block hash") }
        }
    }
}
