//
//  DSSAccountManager.swift
//  DSSToDoListApp
//
//  Created by David on 04/02/22.
//

import Parse

class DSSAccountManager {
    static let shared: DSSAccountManager = .init()
    
    var user: PFUser? { .current() }
    
    private init() { }
    
    func logInWith(username: String, password: String, completion: @escaping (Result<PFUser, Error>) -> Void) {
        PFUser.logInWithUsername(inBackground: username, password: password) { user, error in
            if let error = error { return completion(.failure(error)) }
            
            guard let user = user else {
                let error = NSError(
                    domain: NSStringFromClass(Self.self),
                    code: 0, userInfo: [NSLocalizedDescriptionKey: "PFUser object is nil."]
                )
                return completion(.failure(error))
            }
            
            completion(.success(user))
        }
    }
    
    func signUpWith(username: String, password: String, completion: @escaping (Result<PFUser, Error>) -> Void) {
        let user = PFUser()
        
        user.username = username
        user.password = password
        
        user.signUpInBackground { success, error in
            if let error = error { return completion(.failure(error)) }
            
            guard success else {
                let error = NSError(
                    domain: NSStringFromClass(Self.self),
                    code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to signUp"]
                )
                return completion(.failure(error))
            }
            
            completion(.success(user))
        }
    }
    
    func logOut(completion: @escaping (Error?) -> Void) {
        PFUser.logOutInBackground(block: completion)
    }
}
