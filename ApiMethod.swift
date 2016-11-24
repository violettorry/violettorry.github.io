//
//  ApiMethod.swift
//  proveng
//
//  Created by Виктория Мацкевич on 10.07.16.
//  Copyright © 2016 Provectus. All rights reserved.
//

//Group Data:

import Foundation
import Alamofire
import ObjectMapper
import PromiseKit

/**
 Object encapsulates request parameters
 - Parameters:
 - parameters: param of request
 - path: url path of request
 - method: Alamofire.Method
 */
enum ApiMethod: Hashable {
    
    //MARK: User
    case getUserProfile(userID: Int)
    case updateUserProfile(user: User)
    case loginUser(gToken: String)
    case logoutUser(token: String)
    case getUsers(roleName: String)
    case getUsersCountForLevels
    case getUsersStartTest(level: String?)
    case deleteGroupUser(groupID: Int, userID: Int, note: String)
    case getUsersStatusForEvent(eventID: Int)
    //MARK: Group
    case getGroup(groupID: Int)
    case getGroups
    case createGroup(group: Group)
    case updateGroup(group: Group)
    case deleteGroup(groupID: Int)
    //MARK: Event
    case getEvent(eventID: Int)
    case getEvents(userID: Int)
    case getCalendar(userID: Int, date: Double)
    case getFeed(userID: Int)
    case createEvent(event: Event)
    case updateEvent(event: Event)
    case deleteEvent(eventID: Int)
    case acceptEvent(eventID: Int)
    case cancelEvent(eventID: Int)
    case createVisitedEvent(eventID: Int, groupID: Int, visitedMembers: [UserPreview])
    //MARK: Schedule
    case getSchedule(groupID: Int)
    case createSchedule(groupID: Int, schedule: [EventPreview])
    case editSchedule(groupID: Int, schedule: [EventPreview])
    //MARK: BaseData
    case getLocations
    case getDepartments
    case getLevels
    //MARK: Test
    case getTests
    case getTest(id: Int)
    case resultTest(test: Test, duration:Double)
    //MARK: Materials
    case getMaterials
    case getMaterial(materialID: Int)
    case createMaterial(material: Material)
    case editMaterial(material: Material)
    case openMaterial(materialID: Int, groupID: Int)

    var parameters: [String: AnyObject] {
        let userIDKey = "userId"
        let groupIDKey = "groupId"
        let IDKey = "id"
        let roleNameKey = "roleName"
        let testIDKey = "testId"
        let durationKey = "duration"
        let dateKey = "date"
        switch self {
        //MARK: User
        case .getUserProfile(let userID):
            return [IDKey: userID as AnyObject]
        case .logoutUser, .getUsersCountForLevels, .loginUser, .updateUserProfile:
            return [:]
        case .getUsersStartTest(let level):
            if level != nil{
                return ["level": level as AnyObject]
            } else{
                return [:]
            }
        case .getUsers(let roleName):
            return [roleNameKey:roleName as AnyObject]
        case .deleteGroupUser(let groupID, _, _):
            return [groupIDKey: groupID as AnyObject]
        case .getUsersStatusForEvent(let eventID):
            return [IDKey: eventID as AnyObject]
        //MARK: Group
        case .getGroup(let groupID):
            return [IDKey: groupID as AnyObject]
        case .createGroup, .updateGroup, .getGroups:
            return [:]
        case .deleteGroup(let groupID):
            return [IDKey: groupID as AnyObject]
        //MARK: Event
        case .getEvent(let eventID):
            return [IDKey: eventID as AnyObject]
        case .createEvent, .updateEvent:
            return [:]
        case .getEvents(let userID):
            return [userIDKey: userID as AnyObject]
        case .getCalendar(let userID, let date):
            return [userIDKey: userID as AnyObject,dateKey: date as AnyObject]
        case .getFeed(let userID):
            return [userIDKey: userID as AnyObject]
        case .acceptEvent(let eventID):
            return [IDKey: eventID as AnyObject]
        case .cancelEvent(let eventID):
            return [IDKey: eventID as AnyObject]
        case .deleteEvent(let eventID):
            return [IDKey: eventID as AnyObject]
        case .createVisitedEvent(let eventID, let groupID, _):
            return ["event_id": eventID as AnyObject, "group_id": groupID as AnyObject]
        //MARK: Schedule
        case .getSchedule(let groupID), .createSchedule(let groupID, _), .editSchedule(let groupID, _):
            return ["group_id": groupID as AnyObject]
        //MARK: BaseData
        case .getLocations, .getDepartments, .getLevels:
            return [:]
        //MARK: Test
        case .getTests:
            return [:]
        case .getTest(let id):
            return [IDKey:id as AnyObject]
        case .resultTest(let test, let duration):
            return [testIDKey: test.objectID as AnyObject,durationKey: duration as AnyObject]
        //MARK: Materials
        case .getMaterials, .createMaterial, .editMaterial:
            return [:]
        case .getMaterial(let id):
            return [IDKey:id as AnyObject]
        case .openMaterial(let materialID, let groupID):
            return ["material_id": materialID as AnyObject, "group_id": groupID as AnyObject]
        }
    }
    
    var path: String {
        switch self {
        //MARK: User
        case .getUserProfile, .updateUserProfile:
            return "user"
        case .loginUser:
            return "auth-by-google"
        case .logoutUser:
            return "logout"
        case .getUsers:
            return "users"
        case .getUsersCountForLevels:
            return "usersLevel"
        case .getUsersStartTest:
            return "usersStartTest"
        case .deleteGroupUser:
            return "group_users"
        case .getUsersStatusForEvent:
            return "eventUsersStatus"        
        //MARK: Group
        case .getGroup, .createGroup, .updateGroup:
            return "group"
        case .deleteGroup:
            return "group"
        case .getGroups:
            return "groups"
        //MARK: Event
        case .getEvent, .updateEvent, .deleteEvent, .createEvent:
            return "event"
        case .getEvents:
            return "events"
        case .getCalendar:
            return "calendar"
        case .getFeed:
            return "feed"
        case .acceptEvent:
            return "eventAccepted"
        case .cancelEvent:
            return "eventDenied"
        case .createVisitedEvent:
            return "eventVisited"
        //MARK: Schedule
        case .createSchedule, .getSchedule, .editSchedule:
            return "schedule"
        //MARK: BaseData
        case .getLocations:
            return "locations"
        case .getDepartments:
            return "departments"
        case .getLevels:
            return "levels"
        //MARK: Test
        case .getTests:
            return "tests"
        case .getTest:
            return "test"
        case .resultTest:
            return "test_result"
        //MARK: Materials
        case .getMaterials:
            return "materials"
        case .getMaterial, .createMaterial, .editMaterial:
            return "material"
        case .openMaterial:
            return "openMaterial"
        }
    }
    var additionalHeaders: [String: String]{
        let tokenKey = "token"
        switch self {
        case .loginUser:
            return [:]
        default:
            return [tokenKey: SessionData.token]
        }
    }
    
    var body: String {
        let tokenKey = "gToken"
        let userIDKey = "userId"
        let noteKey = "note"
        switch self {
        case .updateUserProfile(let user):
            return Mapper<User>(context: ContextType.write).getJsonStringFromOblect(user)
        case .createSchedule(_, let schedule), .editSchedule(_, let schedule):
            return Mapper<EventPreview>(context: ContextType.write).getJsonStringFromArray(schedule)
        case .loginUser(let gToken):
            let jsonBody: JSON =  [tokenKey: gToken]
            if let stringBody = jsonBody.rawString(){
                return stringBody
            } else {
                return ""
            }
        case .updateEvent(let event), .createEvent(let event):
            return Mapper<Event>(context: ContextType.write).getJsonStringFromOblect(event)
        case .updateGroup(let group), .createGroup(let group):
            return Mapper<Group>(context: ContextType.write).getJsonStringFromOblect(group)
        case .resultTest(let test, _):
            let answers = test.cards.filter{ $0.answer != nil }
            return Mapper<TestCard>(context: ContextType.write).getJsonStringFromArray(Array(answers))
        case .deleteGroupUser(_, let userID, let note):
            let jsonBody: JSON =  [[userIDKey: userID, noteKey: note]]
            if let stringBody = jsonBody.rawString(){
                return stringBody
            } else {
                return ""
            }
        case .createVisitedEvent(_, _, let visitedMembers):
            return Mapper<UserPreview>(context: ContextType.short).getJsonStringFromArray(visitedMembers)
        case .createMaterial(let material), .editMaterial(let material):
            return Mapper<Material>().getJsonStringFromOblect(material)
        default:
            return ""
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .loginUser, .logoutUser, .createGroup, .createEvent, .createSchedule, .acceptEvent, .cancelEvent, .resultTest, .createVisitedEvent, .createMaterial, .openMaterial:
            return .post
        case .getUserProfile, .getGroup, .getGroups, .getUsers, .getUsersCountForLevels, .getUsersStatusForEvent, .getEvent, .getEvents, .getCalendar, .getFeed, .getUsersStartTest, .getSchedule, .getLocations, .getDepartments, .getLevels, .getTest, .getTests, .getMaterials, .getMaterial:
            return .get
        case .updateGroup, .updateEvent, .updateUserProfile, .editSchedule, .editMaterial:
            return .put
        case .deleteGroup, .deleteEvent, .deleteGroupUser:
            return .delete
        }
    }
    
    var hashValue: Int {
        let value = self.path + self.method.rawValue
        return value.hashValue// + address(o: &value)
    }
    
    func address(o: UnsafeRawPointer) -> Int {
        return unsafeBitCast(o, to: Int.self)
    }
}

func == (lhs: ApiMethod, rhs: ApiMethod) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
