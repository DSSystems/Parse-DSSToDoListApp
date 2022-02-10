//
//  DSSToDoItem.swift
//  DSSToDoListApp
//
//  Created by David on 09/02/22.
//

import ParseSwift

struct DSSToDoItem: ParseObject {
    var originalData: Data?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    var title: String?
    var description: String?
    
    func merge(with object: DSSToDoItem) throws -> DSSToDoItem {
        var updated = try mergeParse(with: object)
        
        if shouldRestoreKey(\.title, original: object) { updated.title = title }
        
        if shouldRestoreKey(\.description, original: object) { updated.description = description }
        
        return updated
    }
}

extension DSSToDoItem {
    init(title: String, description: String?) {
        self.title = title
        self.description = description
    }
    
    init(objectId id: String) { objectId = id }
}
