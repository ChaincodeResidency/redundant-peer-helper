//
//  HttpAuth.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/30/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** HTTP Authentication Token
 */
struct HttpAuth {
    /** String concatenated representation of auth
     */
    private let _authData: Data
    
    /** Auth string as data
     */
    private static func _authData(fromString string: String) -> Data? {
        return string.data(using: .utf8, allowLossyConversion: true)
    }
    
    /** Create Auth
     */
    init?(password: String, user: String) {
        let authString = "\(user):\(password)"
        
        guard let authData = type(of: self)._authData(fromString: authString) else { return nil }
        
        _authData = authData
    }
    
    /** Create auth from credentials string
     */
    init?(credentials: String?) {
        guard let credentials = credentials, let authData = type(of: self)._authData(fromString: credentials) else { return nil }
        
        _authData = authData
    }
    
    /** As a wire encoded string
     */
    var asBase64Encoded: String {
        return _authData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
