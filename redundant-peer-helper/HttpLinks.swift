//
//  HttpLinks.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/28/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Get formatted links from links header
 */
struct HttpLinks {
    // MARK: - Init
    
    /** Derive links from link header string value
    */
    init?(fromLinkHeaderValue: String) {
        guard !fromLinkHeaderValue.isEmpty else { return nil }
        
        let linkPattern = "rel=\\\"?([^\\\"]+)\\\"?"
        
        guard let relRegex = try? NSRegularExpression(pattern: linkPattern, options: .caseInsensitive) else {
            return nil
        }
        
        let charactersToTrim = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "<>"))
        var parsedLinks = [String: String]()
        
        fromLinkHeaderValue.components(separatedBy: ",").forEach { link in
            guard let semicolonPosition = link.range(of: ";") else { return }
            
            let target = link
                .substring(to: semicolonPosition.lowerBound)
                .trimmingCharacters(in: charactersToTrim)
            
            guard !target.isEmpty else { return }
            
            if let match = relRegex.firstMatch(
                in: link,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSMakeRange(0, link.characters.count))
            {
                let type = (link as NSString).substring(with: match.rangeAt(1))
                
                parsedLinks[type] = target
            }
        }
        
        current = parsedLinks["current"]
        next = parsedLinks["next"]
    }
    
    /** Derive links from url response
     */
    init?(fromUrlResponse: URLResponse?) {
        guard
            let headers = (fromUrlResponse as? HTTPURLResponse)?.allHeaderFields as? [String: String],
            let links = (headers["Link"] ?? headers["link"]) as String?,
            let httpLinks = type(of: self).init(fromLinkHeaderValue: links)
            else
        {
            return nil
        }

        self = httpLinks
    }

    // MARK: - Properties
    
    /** Current link
    */
    let current: String?
    
    /** Next link
    */
    let next: String?
}
