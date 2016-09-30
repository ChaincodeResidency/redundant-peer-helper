//
//  HttpStatusCode.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** HTTP Status code
 */
enum HttpStatusCode: Int {
    /** No body
    */
    case noContent = 204

    /** Resource not found
    */
    case notFound = 404
    
    /** Success
    */
    case ok = 200
    
    /** Derive status code from a url response
    */
    init?(fromUrlResponse: URLResponse?) {
        guard
            let status = (fromUrlResponse as? HTTPURLResponse)?.statusCode,
            let code = type(of: self).init(rawValue: status)
            else
        {
            return nil
        }
        
        self = code
    }
}
