//
//  LibraryAPI.swift
//  proveng
//
//  Created by Виктория Мацкевич on 08.07.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

typealias CompletionBlock = (Alamofire.Result<Any>) -> Void

public enum Status<Int, ApiError> {
    case success(Int)
    case failure(ApiError)
}

/**
 Class works with request to server
 - Parameters:
 - urlScheme: sheme of request
 - urlHost: url host of request
 - urlPath: common url path of request
 */

struct  ApiLayerConstants {
    static let ProvengURLHost = "proveng.******.com"
    static let ProvengURLScheme = "http"
    static let ProvengURLPath = "/rest/v1/"
    static let ResultKey = "result"
    static let ErrorKey = "error"
    static let ErrorTypeKey = "type"
    static let ErrorCodeKey = "code"
    static let ErrorDescriptionKey = "description"
}

class ApiLayer {
    
    static let SharedApiLayer = ApiLayer(urlScheme: ApiLayerConstants.ProvengURLScheme, urlHost: ApiLayerConstants.ProvengURLHost, urlPath: ApiLayerConstants.ProvengURLPath)
    
    let urlScheme: String
    let urlHost: String
    let urlPath: String
    let manager: Alamofire.SessionManager
    var activeRequests: [ApiMethod: Alamofire.DataRequest] = [:]
    
    init(urlScheme: String, urlHost: String, urlPath: String){
        self.urlHost = urlHost
        self.urlScheme = urlScheme
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.manager = Alamofire.SessionManager(configuration: configuration)
        self.urlPath = urlPath
    }
    
    /**
     Method initializes Alamofire request and returns NSDictionary
     - Parameters:
     - apiMethod: ApiMethod
     - Returns: Promise<[String: AnyObject]>
     */
    
    func requestWithDictionaryPromise(_ apiMethod: ApiMethod) -> Promise<[String: AnyObject]>{
        return firstly {
            self.requestForResult(apiMethod)
        }.then { data -> Promise<[String: AnyObject]> in
            guard let object = data["result"] as? [String: AnyObject] else {
                return Promise(error: ApiError(code: 048, userInfo: [NSLocalizedDescriptionKey as NSObject:"No object in result" as AnyObject]))

            }
            return Promise(value: object)
        }
    }

    /**
     Method initializes Alamofire request and returns NSDictionary of AnyObject
     - Parameters:
     - apiMethod: ApiMethod
     - Returns: Promise<[AnyObject]>
     */
    
    func requestWithDictionaryOfAnyObjectsPromise(_ apiMethod: ApiMethod) -> Promise<[AnyObject]>{
        return firstly {
            self.requestForResult(apiMethod)
        }.then { data -> Promise<[AnyObject]> in
            guard let objects: [AnyObject] = data["result"] as? [AnyObject] else {
                return Promise(error: ApiError(code: 048, userInfo: [NSLocalizedDescriptionKey as NSObject:"No object in result" as AnyObject]))
            }
            return Promise(value: objects)
        }
    }
    
    func requestForResult(_ apiMethod: ApiMethod) -> Promise<[String: AnyObject]>{
        return Promise { fulfill, reject in
            sendRawRequest(apiMethod) { result in
                switch result {
                case .success(let value):
                    guard let data = value as? [String: AnyObject] else {
                        reject(ApiError(errorDescription: "Invalid JSON"))
                        return
                    }
                    guard data[ApiLayerConstants.ResultKey] != nil else {
                        var apiError = ApiError(errorDescription: "")
                        if let errorDict = data[ApiLayerConstants.ErrorKey], let errorDescription = errorDict[ApiLayerConstants.ErrorDescriptionKey] as? String,  let errorType = errorDict[ApiLayerConstants.ErrorTypeKey] as? String {
                            var intErrorCode = 0
                            if let errorCode = errorDict[ApiLayerConstants.ErrorCodeKey] as? String, let intError = Int(errorCode){
                                intErrorCode = intError
                            } else if let errorCode = errorDict[ApiLayerConstants.ErrorCodeKey] as? Int {
                                intErrorCode = errorCode
                            }
                            apiError = ApiError(domain: errorType, code: intErrorCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                        }
                        reject(apiError)
                        return
                    }
                    fulfill(data)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }

    /**
     Method initializes Alamofire request and returns NSData
     - Parameters:
     - apiMethod: ApiMethod
     - Returns: Alamofire.Result<NSData, ApiError>
     */
    
    func sendRawRequest(_ apiMethod: ApiMethod, completion: @escaping (Alamofire.Result<Any>) -> ()) {
        let path = apiMethod.path
        let parameters = apiMethod.parameters
        let method = apiMethod.method
        let additionalHeaders = apiMethod.additionalHeaders
        let body = apiMethod.body
        var urlComponents =  URLComponents()
        urlComponents.scheme = urlScheme
        urlComponents.host = urlHost
        urlComponents.path = urlPath + path
        if parameters.count > 0{
            urlComponents.query = parameters.stringFromHttpParameters()
        }
        let urlRequest = urlComponents.url
        self.activeRequests.removeValue(forKey: apiMethod)
        let request = manager.request(urlRequest!, method: method, parameters: parameters, encoding: body, headers: additionalHeaders).responseJSON { [weak self] response in
            if let weakSelf = self {
                weakSelf.activeRequests.removeValue(forKey: apiMethod)
            }
            switch response.result {
            case .success:
                guard response.data != nil else {
                    let error: ApiError = ApiError(domain: self?.urlHost,userInfo: [NSLocalizedDescriptionKey: "Data ERROR"])
                    completion(.failure(error))
                    return
                }
                print("JSON From Backend: \(response.result.value)")
                guard response.result.value != nil else {
                    let error: ApiError = ApiError(domain: self?.urlHost, userInfo: [NSLocalizedDescriptionKey: "JSON ERROR"])
                    completion(.failure(error))
                    return
                }
                completion(.success(response.result.value!))
            case .failure(let error):
                // let error: ApiError = ApiError(domain: err.domain, code: err.code, userInfo: err.userInfo)
                completion(.failure(error))
            }
        }
        self.activeRequests[apiMethod] = request
    }
    
    func cancel(_ method: ApiMethod?) {
        guard let method = method else {
            return
        }
        if let request = self.activeRequests[method] {
            request.cancel()
            print("CANCEL \(request)")
        } else {
            print("NOT CANCEL \(self)")
        }
    }
    
    func cancelAll() {
        print("Start Cancelling")
        for request in self.activeRequests.values {
            request.cancel()
            print("CANCEL any \(request)")
        }
    }
}

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }    
}
