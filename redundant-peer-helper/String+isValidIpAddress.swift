//
//  String+isValidIpAddress.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

// MARK: - String IP address
extension String {
    /** Determine if a string is a valid ip address
     */
    var isValidIpAddress: Bool {
        var sockIn = sockaddr_in()
        var sockIn6 = sockaddr_in6()
        
        // Test for IP version 4
        if withCString({ inet_pton(AF_INET, $0, &sockIn.sin_addr) }) == 1 { return true }
        
        // Test for IP version 6
        if withCString({ inet_pton(AF_INET6, $0, &sockIn6.sin6_addr) }) == 1 { return true }
        
        return false;
    }
}
