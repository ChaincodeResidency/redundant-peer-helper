//
//  TestHttpLinks.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 10/4/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import XCTest

class TestHttpLinks: XCTestCase {
    /** Sample current path
    */
    private let _currentPath = "https://api.example.com/path/to/valid?a=1&b=2&c=3"
    
    /** Sample next path
    */
    private let _nextPath = "http://api.example.com/path/to/valid?a=1&b=2&c=3"
    
    /** Confirm that at empty link value does not yield any links
    */
    func testFailingToParseEmptyLink() {
        XCTAssertNil(HttpLinks(fromLinkHeaderValue: String()), "Expected no links")
    }
    
    /** Check if the parser can deal with rels that aren't quoted
     */
    func testHandlingUnquotedRelationships() {
        let linkHeaderValue = "<" + _nextPath + ">; rel=next, <" + _currentPath + ">; rel=current"
        
        guard let parsed = HttpLinks(fromLinkHeaderValue: linkHeaderValue) else {
            return XCTFail("Expected valid links header")
        }
        
        XCTAssertEqual(parsed.next, _nextPath)
        
        XCTAssertEqual(parsed.current, _currentPath)
    }
    
    /** Confirm that links need to have a rel
     */
    func testParsingNoRelLink() {
        let linkHeaderValue = "<" + _nextPath + ">; rel=\"next\", <" + _currentPath + ">; invalid=\"nothing\""
        
        guard let parsed = HttpLinks(fromLinkHeaderValue: linkHeaderValue) else {
            return XCTFail("Expected valid links header")
        }
        
        XCTAssertEqual(parsed.next, _nextPath)
        
        XCTAssertNil(parsed.current, "Expected no current link")
    }

    /** Check if the parser can deal with a well formed link header value
    */
    func testParsingWellFormedLinkHeader() {
        let linkHeaderValue = "<" + _nextPath + ">; rel=\"next\", <" + _currentPath + ">; rel=\"current\""
        
        guard let parsed = HttpLinks(fromLinkHeaderValue: linkHeaderValue) else {
            return XCTFail("Expected valid links header")
        }
        
        XCTAssertEqual(parsed.next, _nextPath)
        
        XCTAssertEqual(parsed.current, _currentPath)
    }
}
