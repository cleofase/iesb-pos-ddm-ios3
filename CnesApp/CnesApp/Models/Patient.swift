//
//  User.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 26/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import Foundation
import FirebaseAuth
import CoreData
import UIKit

class Patient: NSManagedObject {
    class func find(matching patientId: String, in context: NSManagedObjectContext) throws -> Patient? {
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        request.predicate = NSPredicate(format: "patientId = %@", patientId)
        do {
            let maches = try context.fetch(request)
            if maches.count > 0 {
                return maches[0]
            }
        } catch {
            throw error
        }
        return nil
    }
    
    class func create(with firebaseUser: User, in context: NSManagedObjectContext) throws -> Patient {
        let patient = Patient(context: context)
        patient.patientId = firebaseUser.uid
        patient.userName = firebaseUser.displayName
        patient.email = firebaseUser.email
        return patient
    }
    
    class func findOrCreate(matching user: User, in context: NSManagedObjectContext) throws -> Patient {
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        request.predicate = NSPredicate(format: "patientId = %@", user.uid)
        do {
            let maches = try context.fetch(request)
            if maches.count > 0 {
                return maches[0]
            } else {
                let patient = Patient(context: context)
                patient.patientId = user.uid
                patient.userName = user.displayName
                patient.email = user.email
                return patient
            }
        } catch {
            throw error
        }
    }
    
    func dictionaryValue() -> [String: Any] {
        return [
            "name": self.name ?? "",
            "email": self.email ?? "",
            "patientId": self.patientId ?? ""
        ]
    }
}
