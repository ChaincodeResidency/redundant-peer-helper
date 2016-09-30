//
//  BlockHash.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/30/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Hash of block data
 */
struct BlockHash {
    /** Hash value
     */
    private let _hashValue: String
    
    /** Derive a block hash from a string
     */
    init?(forString: String?) {
        guard let hash = forString, !hash.isEmpty else { return nil }
        
        _hashValue = hash
    }
    
    /** As string
     */
    var asString: String { return _hashValue }
}
