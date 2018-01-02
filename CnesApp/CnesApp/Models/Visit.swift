//
//  Visit.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 30/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Visit: NSManagedObject {
    class func createOrUpdate(in context: NSManagedObjectContext, withPatient patient: Patient, healthUnitId: String, regionInTime: Date? = nil, regionOutTime: Date? = nil, checkedIn: Bool? = nil) throws -> Visit {
        let visit: Visit?
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "patient.patientId == %@ and healthUnitId == %@ and opened == true", patient.patientId!, healthUnitId)
        do {
            let maches = try context.fetch(request)
            if maches.count > 0 {
                visit = maches[0]
            } else {
                visit = Visit(context: context)
                visit!.opened = true
            }
            visit!.patient = patient
            visit!.healthUnitId = healthUnitId
            if let _ = regionInTime {
                visit!.regionInTime = regionInTime!
            }
            visit!.regionInTime = regionInTime
            if let _ = regionOutTime {
                visit!.regionOutTime = regionOutTime!
                visit!.opened = false
            }
            if let _ = checkedIn {
                visit!.checkedIn = checkedIn!
            }
            return visit!
        } catch {
            throw error
        }
    }
    
    class func find(in context: NSManagedObjectContext, matchingPatientId patientId: String) throws -> [Visit]? {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "patient.patientId == %@", patientId)
        do {
            let maches = try context.fetch(request)
            if maches.count > 0 {
                return maches
            } else {
                return nil
            }
        } catch {
            throw error
        }
    }
    
}
