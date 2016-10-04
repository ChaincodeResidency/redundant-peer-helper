//
//  LocalCoreRequest.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/27/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Foundation

/** Make a request to local core
 
    FIXME: - make the core URL configurable
    FIXME: - make auth / bitcoin conf file configurable
 */
struct LocalCoreRequest {
    // MARK: - Properties
    
    /** Default local core URL
    */
    private static let _defaultCoreUrl = URL(string: "http://localhost:8332/")
    
    /** Request type
     */
    private let _method: LocalCoreRpcMethod
    
    /** Request id
     */
    fileprivate let _requestId: TimeInterval
    
    /** Network endpoint
     */
    private let _url: URL
    
    /** Create request
     */
    init?(method: LocalCoreRpcMethod) {
        guard let endpoint = type(of: self)._defaultCoreUrl else { return nil }
        
        _url = endpoint
        
        _method = method
        
        _requestId = NSDate().timeIntervalSince1970
    }
    
    // MARK: - Auth
    
    /** Get auth token for a request
     */
    private static func _getAuth() throws -> HttpAuth {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw LocalCoreRequestError.missingCredentials
        }
        
        let serializedCookieAuth = try String(contentsOf: dir.appendingPathComponent("Bitcoin/.cookie"))
        
        guard let cookieAuth = HttpAuth(credentials: serializedCookieAuth) else {
            throw LocalCoreRequestError.missingCredentials
        }
        
        return cookieAuth
    }
    
    // MARK: - Errors
    
    /** Core request error
     */
    enum LocalCoreRequestError: Error {
        case jsonRequestBodySerializationFailure
        case malformedResponse
        case missingCredentials
        case unexpectedStatusCode
    }
    
    // MARK: - Request
    
    /** Request json body to send
     */
    private var _requestBody: Data? {        
        return try? JSONSerialization.data(withJSONObject: _requestDict, options: .prettyPrinted)
    }
    
    /** Request json dictionary to send
     */
    private var _requestDict: [NSString: AnyObject] {
        return [
            "id": _requestId as NSNumber,
            "method": _method.rpcName as NSString,
            "params": _method.jsonParams
        ]
    }
    
    /** Execute Request
     */
    func execute(cbk: @escaping (_ err: Error?, _ result: Any?) -> ()) {
        let req = NSMutableURLRequest(url: _url)
        
        let hasErr: (Error) -> () = { return cbk($0, nil) }
        let coreRequestErr: (LocalCoreRequestError) -> () = { return hasErr($0) }
        
        guard let reqBody = _requestBody else { return coreRequestErr(.jsonRequestBodySerializationFailure) }
        
        req.httpBody = reqBody
        req.httpMethod = HttpMethod.post.asVerb

        let auth: HttpAuth
        
        do { auth = try type(of: self)._getAuth() } catch let err { return hasErr(err) }
        
        req.setValue("Basic \(auth.asBase64Encoded)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: req as URLRequest) { body, response, err in
            if let err = err { return hasErr(err) }
            
            guard HttpStatusCode(fromUrlResponse: response) == .ok else { return coreRequestErr(.unexpectedStatusCode) }
            
            guard
                let data = body,
                let jsonDictionaryData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let result = (jsonDictionaryData as? NSDictionary)?["result"]
                else
            {
                return coreRequestErr(.malformedResponse)
            }
            
            cbk(nil, result)
        }
        
        task.resume()
    }
}
