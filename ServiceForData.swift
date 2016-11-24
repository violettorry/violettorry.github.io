//
//  ServiceGetData.swift
//  proveng
//
//  Created by Виктория Мацкевич on 15.07.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift
import PromiseKit

class ServiceForData<T:Object> where T:StaticMappable {
    
    func writeDataToStoragePromise(_ data: [String: AnyObject]) -> Promise<T> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            try realm.write{
                print(data)
                guard let realmObject = Mapper<T>().map(JSON: data) else { //Fix
                    return reject(ApiError(code: 3, userInfo: [NSLocalizedDescriptionKey as NSObject:"WRITE to STORAGE ERROR" as AnyObject]))
                }
                realm.add(realmObject, update: true)
                fulfill(realmObject)
            }
            }.recover{ error -> T in
                print(error)
                throw error.apiError
        }
    }
    
    func writeArrayDataToStoragePromise(_ data: [AnyObject]) -> Promise<[T]> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            try realm.write{
                guard let realmObjects = Mapper<T>().mapArray(JSONObject: data) else {
                    return reject(ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                if T.self === Event.self || T.self === FeedEvent.self {
                    detectEvents(objects: realmObjects, realm: realm)
                }
                if T.self === Event.self || T.self === GroupPreview.self || T.self === FeedEvent.self || T.self === MaterialPreview.self || T.self === TestPreview.self {
                    let objectToDelete = realm.objects(T.self)
                    realm.delete(objectToDelete)
                }
                realm.add(realmObjects, update: true)
                fulfill(realmObjects)
            }
            }.recover{ error -> [T] in
                throw error.apiError
        }
    }
    
    func getDataArrayFromStoragePromise(_ sortKey:String? = nil, ascending: Bool = false) -> Promise<Results<T>> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let predicate = NSPredicate(format: "objectID != %i",0)
            var objects = realm.objects(T.self).filter(predicate)
            if let key = sortKey {
                objects = objects.sorted(byProperty: key, ascending: ascending)
            }
            fulfill(objects)
            }.recover { error -> Results<T> in
                throw error.apiError
        }
    }
    
    func getDataByKeyFromStoragePromise(_ filterKey:String, filterValue: String) -> Promise<T> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let predicate = NSPredicate(format: "\(filterKey) =[c] %@", filterValue)
            let objects = realm.objects(T.self).filter(predicate)
            guard objects.count > 0 else{
                return reject(ApiError(errorDescription:"No objects for filter \(T()) \(filterValue)") as NSError)
            }
            fulfill(objects.first!)
            }.recover { error -> T in
                throw error.apiError
        }
    }
    
    func getDataResultsByIDFromStoragePromise(_ objectID: Int) -> Promise<Results<T>> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let predicate = NSPredicate(format: "objectID = %i", objectID)
            let objects = realm.objects(T.self).filter(predicate)
            guard objects.count > 0 else{
                return reject(ApiError(errorDescription:"No objects for id \(T()) \(objectID)") as NSError)
            }
            fulfill(objects)
            }.recover { error -> Results<T> in
                throw error.apiError
        }
    }

    func getDataFromStoragePromise(_ keyValue: AnyObject) -> Promise<T> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let object = realm.object(ofType: T.self, forPrimaryKey: keyValue)
            guard object != nil else{
                return reject(ApiError(errorDescription:"No objects for getting \(T()) \(keyValue)") as NSError)
            }
            fulfill(object!)
            }.recover{ error -> T in
                throw error.apiError
        }
    }
    
    func deleteDataFromStoragePromise(_ keyValue: AnyObject) -> Promise<String> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let objectToDelete = realm.object(ofType: T.self, forPrimaryKey: keyValue)
            try realm.write{
                guard objectToDelete != nil else{
                    return reject(ApiError(errorDescription:"No objects for deleting \(T()) \(keyValue)") as NSError)
                }
                realm.delete(objectToDelete!)
                fulfill("Success")
            }
            }.recover{ error -> String in
                throw error.apiError
        }
    }
    
    func deleteAllDataFromStoragePromise() -> Promise<String> {
        return Promise { fulfill, reject in
            let realm = try Realm()
            let objectToDelete = realm.objects(T.self)
            try realm.write{
                realm.delete(objectToDelete)
                fulfill("Success")
            }
            }.recover{ error -> String in
                throw error.apiError
        }
    }
    
    func getDataFromFilePromise(path: String? = nil) -> Promise<[AnyObject]>{
        return Promise { fulfill, reject in
            guard path != nil else {
                return reject(ApiError(errorDescription: "No such path"))
            }
            let data = try Data(contentsOf: URL(fileURLWithPath: path!), options: .alwaysMapped)
            let jsonObj = JSON(data: data)
            guard jsonObj != JSON.null else{
                return reject(ApiError(errorDescription: "JSON is empty"))
            }
            fulfill(jsonObj.rawArray as [AnyObject])
        }.recover{ error -> [AnyObject] in
            throw error.apiError
        }
    }
    
    func writeBaseDataToStoragePromise(path: String? = nil) -> Promise<[T]> {
        return firstly {
            self.getDataFromFilePromise(path: path)
        }.then { object -> Promise<[T]> in
            return self.writeArrayDataToStoragePromise(object)
        }
    }
}
