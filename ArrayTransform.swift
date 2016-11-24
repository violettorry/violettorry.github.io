//
//  ArrayTransform.swift
//  proveng
//
//  Created by Виктория Мацкевич on 03.08.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class ArrayTransform<T:RealmSwift.Object> : TransformType where T:StaticMappable {

    typealias Object = List<T>
    typealias JSON = [AnyObject]
    
    var mapper = Mapper<T>()
    var context: MapContext
    
    init(context: MapContext? = ContextType.write){
        self.context = context!
    }
    
    func transformFromJSON(_ value: Any?) -> Object? {
        let results = List<T>()
        if let value = value as? [AnyObject] {
            for json in value {
                if let obj = mapper.map(JSON: json as! [String : Any]) {
                    results.append(obj)
                }
            }
        }
        return results
    }
    
    func transformToJSON(_ value: Object?) -> JSON? {
        var results = [AnyObject]()
        if let value = value {
            for obj in value {
                if let contextToJSON = context as? ContextType {
                    mapper = Mapper<T>(context: contextToJSON)
                }
                let json = mapper.toJSON(obj)
                results.append(json as AnyObject)
            }
        }
        return results
    }
}
