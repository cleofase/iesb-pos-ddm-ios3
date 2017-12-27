//
//  ScannerMapViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 17/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseCore
import FirebaseAuth

class ScannerMapViewController: UIViewController {
    var baseLocation: CLLocation?
    var healthUnits = [HealthUnit]()
    
    private var locationManager = CLLocationManager()
    

    @IBOutlet weak var scannerMap: MKMapView! {
        didSet {
            scannerMap.delegate = self
            scannerMap.showsUserLocation = true
        }
    }
    
    override func viewDidLoad() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {locationManager.startUpdatingLocation()}
    }
    
    private func getHealthUnitsAroundMe() {
        guard let _ = baseLocation else {return}
        let appCivico = AppCivico()
        let url = appCivico.healthUnitsUrl(AtLatitude: baseLocation!.coordinate.latitude.description, AndLogitude: baseLocation!.coordinate.longitude.description, UnderRadius: "1000")
        let dataTask = URLSession.shared.dataTask(with: url ) {[unowned self] (data, response, error) in
            if error == nil {
                guard let _ = data else {return}
                let dataDecoder = JSONDecoder()
                do {
                    let newHealthUnits = try dataDecoder.decode([HealthUnit].self, from: data!)
                    self.healthUnits.removeAll()
                    self.healthUnits.append(contentsOf: newHealthUnits)
                    DispatchQueue.main.async {[unowned self] in
                        self.plotHealthUnitsInMap()
                    }
                }catch {
                    print(error.localizedDescription)
                }
                print("Itens retornados: \(self.healthUnits.count.description)")
            } else {print(error.debugDescription)}
        }
        dataTask.resume()
    }
    
    private func plotHealthUnitsInMap() {
        let oldAnnotations = scannerMap.annotations.filter({(annotation) in return annotation.isKind(of: HealthUnitAnnotation.self)})
        scannerMap.removeAnnotations(oldAnnotations)
        
        for healthUnit in healthUnits {
            let annotation = HealthUnitAnnotation(with: healthUnit)
            scannerMap.addAnnotation(annotation)
        }
        
    }
}

extension ScannerMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "reuseHealthUnitAnnotationView"
        let annotationView: MKMarkerAnnotationView
        
        if let annotation = annotation as? HealthUnitAnnotation {
            if let reusableView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView {
                annotationView = reusableView
                annotationView.annotation = annotation
            } else {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView.canShowCallout = true
                annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            return annotationView
        } else {
            if let annotation = annotation as? MKClusterAnnotation {
                print(annotation.memberAnnotations.count)
            }
        }
        
        
        return nil
        
    }
    
//    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
//        <#code#>
//    }
//    
//    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        <#code#>
//    }
}

extension ScannerMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.stopUpdatingLocation()
            let scannerCamera = MKMapCamera(lookingAtCenter: locations.last!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
            scannerMap.setCamera(scannerCamera, animated: true)
            baseLocation = locations.last
            getHealthUnitsAroundMe()
        }
    }
}
