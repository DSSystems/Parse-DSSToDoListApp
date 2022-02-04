//
//  Environment.swift
//  DSSToDoListApp
//
//  Created by David on 04/02/22.
//

import Foundation

class Environment {
    class AppSettings {
        static let applicationId = "MY_PARSE_APPLICATION_ID"
        static let clientKey = "MY_PARSE_CLIENT_KEY"
        static let server = "https://parseapi.back4app.com"
    }
    
    class ServerClass {
        static let toDoList = "ToDoList" // The class name in your Parse App
    }
}
