//
//  HealthUnitAnnotation.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 26/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import Foundation
import MapKit

class HealthUnitAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var healthUnit: HealthUnit
    
    init(with healthUnit: HealthUnit) {
        self.healthUnit = healthUnit
        self.coordinate = CLLocationCoordinate2DMake(healthUnit.lat!, healthUnit.long!)
        self.title = healthUnit.nomeFantasia
        self.subtitle = healthUnit.descricaoCompleta
    }
}
