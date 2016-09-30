//
//  LocalCoreResponse.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Local Core Responses
 */
struct LocalCoreResponses {
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
            
            self.currentHeight = currentHeight.intValue
            
            pruneHeight = (jsonDict["pruneheight"] as? NSNumber)?.intValue
            
            self.bestBlockHash = bestBlockHash as String
        }
    }
}
