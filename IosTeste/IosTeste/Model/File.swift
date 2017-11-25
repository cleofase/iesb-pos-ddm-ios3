//
//  File.swift
//  IosTeste
//
//  Created by HC5MAC10 on 25/11/17.
//  Copyright © 2017 IESB. All rights reserved.
//

import Foundation
import Firebase

struct User: Codable {
    private static let kFirebaseChildName = "user"
    var userUID: String
    var productCount: Int
    var name: String
    var email: String
    var phone: String
    var birthDate: Date
    
    func persist(withCompletionBlock completion: @escaping(Error?, DatabaseReference) -> Void) {
        let ref = Database.database().reference()
        let encoder = JSONEncoder()
        
        do {
            let userData = try encoder.encode(self)
            let dict = try JSONSerialization.jsonObject(with: userData, options: .allowFragments)
            ref.child(User.kFirebaseChildName).child(userUID).setValue(dict, withCompletionBlock: completion)
        } catch {
            completion(error, ref)
        }
        
    }
}
