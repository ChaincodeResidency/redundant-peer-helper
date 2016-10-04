//
//  HttpMethod.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/30/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** HTTP method
 */
enum HttpMethod: String {
    case post = "POST"

    /** As serialized verb
    */
    var asVerb: String { return rawValue }
}
