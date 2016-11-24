//
//  ServiceAuth.swift
//  proveng
//
//  Created by Виктория Мацкевич on 13.07.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import GoogleSignIn
import ObjectMapper

class ServiceAuth: NSObject {
    
    fileprivate var token: String?
    fileprivate var signCompletion: CompletionBlock?
    fileprivate let apiLayer = ApiLayer.SharedApiLayer
    fileprivate let googleSingIn = GIDSignIn.sharedInstance()
    
    override init() {
        super.init()
    }
    
    //MARK: - Actions
    
    func signInWithGoogle(_ completion: @escaping CompletionBlock) {
        prepareForSignWithGoogle(completion)
        googleSingIn?.signIn()
    }
    
    func signOutWithGoogle(_ completion: @escaping CompletionBlock) {
        prepareForSignWithGoogle(completion)
        googleSingIn?.disconnect()
    }
    
    fileprivate func prepareForSignWithGoogle(_ completion: @escaping CompletionBlock) {
        googleSingIn?.delegate = self
        guard signCompletion == nil else {
            completion(.failure(ApiError(errorDescription:"")))
            return
        }
        signCompletion = completion
    }
}

extension ServiceAuth: GIDSignInDelegate {
    
    @objc func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            self.didAuthOperation(.failure(error))
            return
        }
        firstly {
            apiLayer.requestWithDictionaryPromise(ApiMethod.loginUser(gToken: user.authentication.accessToken))
            }.then { sessionDictionary -> Void in
                guard let sessionObject = Mapper<Session>().map(JSON: sessionDictionary) else {
                    return self.didAuthOperation(.failure(ApiError(code: 3, userInfo: [NSLocalizedDescriptionKey as NSObject:"WRITE to STORAGE ERROR" as AnyObject])))
                }
                return self.didAuthOperation(.success(sessionObject))
            }.catch { error in
                return self.didAuthOperation(.failure(error.apiError))
        }
    }
    
    @objc func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print("Google sign out error \(error)")
        }
        if !SessionData.token.isEmpty {
            let promiseForLogout = ServiceForRequest<Session>().deleteObjectPromise(SessionData.id as AnyObject, operation: ApiMethod.logoutUser(token: SessionData.token))
            let promiseForDeletingTables = ServiceForData<EventPreview>().deleteTablesAfterLogoutPromise()
        
            when(resolved: [promiseForLogout, promiseForDeletingTables]
                ).then { results in
                    return self.didAuthOperation(.success(results))
                }.catch { error in
                    return self.didAuthOperation(.failure(error.apiError))
            }
        }
    }
    
    func didAuthOperation(_ result: Alamofire.Result<Any>) -> Void {
        self.signCompletion?(result)
        self.signCompletion = nil
    }
}
