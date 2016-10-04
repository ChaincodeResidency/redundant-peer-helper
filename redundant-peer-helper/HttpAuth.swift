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
    // MARK: - Init
    
    /** Create Auth
     */
    init?(password: String, user: String) {
        let authString = [user, password].joined(separator: type(of: self)._separator)
        
        guard let authData = type(of: self)._authData(fromString: authString) else { return nil }
        
        _authData = authData
    }
    
    /** Create auth from credentials string
     */
    init?(credentials: String?) {
        guard
            let credentials = credentials,
            let authData = type(of: self)._authData(fromString: credentials)
            else
        {
            return nil
        }
        
        _authData = authData
    }
    
    // MARK: - Properties (Private)
    
    /** String concatenated representation of auth
     */
    fileprivate let _authData: Data
    
    /** Auth string as data
     */
    private static func _authData(fromString string: String) -> Data? {
        return string.data(using: .utf8, allowLossyConversion: true)
    }
    
    /** Separation between user and pass
    */
    private static let _separator = ":"
}

// MARK: - Encoding
extension HttpAuth {
    /** As a wire encoded string
     */
    var asBase64Encoded: String {
        return _authData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}
