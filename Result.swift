//
//  Result.swift
//  proveng
//
//  Created by Виктория Мацкевич on 09.08.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import Alamofire

extension Result{
    func mapResult<T>(_ f:(Value) -> T) -> Result<T> {
        switch self {
        case .success(let value):
            return .success(f(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func flatMap<T>(_ f:(Value) throws -> T) -> Result<T> {
        switch self {
        case .success(let value):
            do {
                let unknownResult = try f(value);
                return .success(unknownResult);
                
            }catch let error {
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
}

