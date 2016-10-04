//
//  IpAddress.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Internet Protocol Address
 */
struct IpAddress {
    /** String value
     */
    let stringValue: String
    
    /** Create from string
     */
    init?(withAddress: String) {
        guard withAddress.isValidIpAddress else { return nil }
        
        stringValue = withAddress
    }
    
    /** Create from url String
     */
    init?(withUrlString: String) {
        guard let address = URL(string: withUrlString)?.host else { return nil }
        
        stringValue = address
    }
}
