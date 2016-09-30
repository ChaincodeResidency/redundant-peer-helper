//
//  HexSerializedBlock.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Serialized block
 */
struct HexSerializedBlock {
    /** String value
     */
    let stringValue: String
    
    /** Derive a hex serialized block from a string
     */
    init?(forString: String?) {
        guard let block = forString, !block.isEmpty else { return nil }
        
        stringValue = block
    }
}
