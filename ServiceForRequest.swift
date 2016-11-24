//
//  ServiceForRequest.swift
//  proveng
//
//  Created by Виктория Мацкевич on 31.08.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import PromiseKit

class ServiceForRequest<T:Object> : ServiceForData<T> where T:StaticMappable {
    
    fileprivate var apiLayer = ApiLayer.SharedApiLayer
    
    func getObjectPromise(_ operation: ApiMethod) -> Promise<T>{
        return firstly{
            return self.apiLayer.requestWithDictionaryPromise(operation)
        }.then { data in
            return self.writeDataToStoragePromise(data)
        }
    }
    
    @discardableResult func getObjectsPromise(_ operation: ApiMethod) -> Promise<[T]>{
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        return firstly{
            return self.apiLayer.requestWithDictionaryOfAnyObjectsPromise(operation)
        }.then { data in
            return self.writeArrayDataToStoragePromise(data)
        }
    }
    
    func deleteObjectPromise(_ keyValue: AnyObject, operation: ApiMethod) -> Promise<String>{
        return firstly{
            return self.apiLayer.requestWithDictionaryPromise(operation)
        }.then { data in
            return self.deleteDataFromStoragePromise(keyValue)
        }
    }
    
    func getLevelObjects(_ method: ApiMethod) -> Promise<[T]>{
        return firstly{
            return self.apiLayer.requestWithDictionaryPromise(method)
        }.then { data in
            var levels = [[String : Any]]()
            var i = 1
            for (key, value) in data {
                if let count = value as? Int {
                    let level: [String: Any] = ["id": i ,"name": key, "count": count]
                    levels.append(level)
                    i += 1
                }
            }
            return self.writeArrayDataToStoragePromise(levels as [AnyObject])
        }
    }
    
    
    
    func createGroupPromise(group: Group) -> Promise<Group> {
        return firstly{
            return self.apiLayer.requestWithDictionaryPromise(ApiMethod.createGroup(group: group))
        }.then { groupDictionary -> Promise<Group> in
            guard let groupObject = Mapper<Group>().map(JSON: groupDictionary) else {
                return Promise(error: ApiError(code: 3, userInfo: [NSLocalizedDescriptionKey as NSObject:"WRITE to STORAGE ERROR" as AnyObject]))
            }
            let realm = try Realm()
            let groupPreview = GroupPreview()
            groupPreview.objectID = groupObject.objectID
            groupPreview.groupLevel = groupObject.groupLevel
            groupPreview.groupName = groupObject.groupName
            groupPreview.primaryGroupFlag = groupObject.primaryGroupFlag
            try realm.write{
                realm.add(groupObject, update: true)
                realm.add(groupPreview, update: true)
            }
            return Promise(value: groupObject)
        }
    }
    
    func createSchedulePromise(group: Group, schedule: [EventPreview]) -> Promise<Group> {
        var finallyGroup = Group()
        return firstly {
            return BaseModel.mappedCopy(group, context: false)
        }.then{ group -> Promise<[AnyObject]> in
            finallyGroup = group
           return self.apiLayer.requestWithDictionaryOfAnyObjectsPromise(ApiMethod.createSchedule(groupID: group.objectID, schedule: schedule))
        }.then {scheduleDictionary -> Promise<Group> in
            guard let scheduleObjects = Mapper<EventPreview>().mapArray(JSONObject: scheduleDictionary) else {
                return Promise(error: ApiError(code: 3, userInfo: [NSLocalizedDescriptionKey as NSObject:"WRITE to STORAGE ERROR" as AnyObject]))
            }
            for event in scheduleObjects {
                if event.type == Constants.LifetimeType {
                    finallyGroup.lifetimeEvent = event
                } else {
                    finallyGroup.scheduleEvents.append(event)
                }
            }
            let realm = try Realm()
            try realm.write{
                realm.add(finallyGroup, update: true)
            }
            return Promise(value: finallyGroup)
        }
    }
    
    func editGroupWithShedulePromise(group: Group, schedule: [EventPreview]) -> Promise<Group> {
        var finallyGroup = Group()
        let promisePutGroup = self.apiLayer.requestWithDictionaryPromise(ApiMethod.updateGroup(group: group))
        let promisePutShedule = self.apiLayer.requestWithDictionaryOfAnyObjectsPromise(ApiMethod.editSchedule(groupID: group.objectID, schedule: schedule))
        return when(fulfilled: [promisePutGroup.asVoid(), promisePutShedule.asVoid()]).then { _ -> Promise<Group> in
            if let groupDictionary = promisePutGroup.value {
                guard let groupObject = Mapper<Group>().map(JSON: groupDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                finallyGroup = groupObject
            }
            if let scheduleDictionary = promisePutShedule.value {
                guard let scheduleObjects = Mapper<EventPreview>().mapArray(JSONObject: scheduleDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                for event in scheduleObjects {
                    if event.type == Constants.LifetimeType {
                        finallyGroup.lifetimeEvent = event
                    } else {
                        finallyGroup.scheduleEvents.append(event)
                    }
                }
            }
            let realm = try Realm()
            try realm.write{
                realm.add(finallyGroup, update: true)
            }
            return Promise(value: finallyGroup)
        }
    }
    
    
    
    func getGroupWithShedulePromise(groupMethod: ApiMethod, scheduleMethod: ApiMethod) -> Promise<Group> {
        var group = Group()
        let promiseGetGroup = self.apiLayer.requestWithDictionaryPromise(groupMethod)
        let promiseGetShedule = self.apiLayer.requestWithDictionaryOfAnyObjectsPromise(scheduleMethod)
        return when(resolved: [promiseGetGroup.asVoid(), promiseGetShedule.asVoid()]).then { _ -> Promise<Group> in
            if let groupDictionary = promiseGetGroup.value {
                guard let groupObject = Mapper<Group>().map(JSON: groupDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                group = groupObject
            }
            if let scheduleDictionary = promiseGetShedule.value {
                guard let scheduleObjects = Mapper<EventPreview>().mapArray(JSONObject: scheduleDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                for event in scheduleObjects {
                    if event.type == Constants.LifetimeType {
                        group.lifetimeEvent = event
                    } else {
                        group.scheduleEvents.append(event)
                    }
                }
            }
            let realm = try Realm()
            try realm.write{
                realm.add(group, update: true)
            }
            return Promise(value: group)
        }
    }
    
    func getEventWithMembersPromise(groupMethod: ApiMethod, eventMethod: ApiMethod) -> Promise<T> {
        var newEvent = T() is FeedEvent  ? FeedEvent() : Event()
        let promiseGetEvent = self.apiLayer.requestWithDictionaryPromise(eventMethod)
        let promiseGetGroup = self.apiLayer.requestWithDictionaryPromise(groupMethod)
        let promiseArray = [promiseGetEvent.asVoid(), promiseGetGroup.asVoid()]
        return when(resolved: promiseArray).then { _ -> Promise<T> in
            if let eventDictionary = promiseGetEvent.value {
                guard let eventObject = Mapper<T>().map(JSON: eventDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                newEvent = eventObject as! Event
            }
            if let groupDictionary = promiseGetGroup.value {
                guard let groupObject = Mapper<Group>().map(JSON: groupDictionary) else {
                    return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
                }
                newEvent.members = groupObject.members
            }
            let realm = try Realm()
            try realm.write{
                realm.add(newEvent, update: true)
            }
            return Promise(value: newEvent as! T)
        }
    }
    
    func getUsersStatusForEventPromise(eventID: Int) -> Promise<[T]> {
        return firstly {
            self.apiLayer.requestWithDictionaryOfAnyObjectsPromise(ApiMethod.getUsersStatusForEvent(eventID: eventID))
        }.then { statusDictionary -> Promise<[T]> in
            guard let eventObject = Mapper<T>().mapArray(JSONObject: statusDictionary) else {
                return Promise(error: ApiError(errorDescription: "WRITE to STORAGE ERROR"))
            }
            return Promise(value: eventObject)
        }
    }
}
