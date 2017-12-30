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
    private var pulseActivityIndicator = PulseActivityIndicator()
    private var firstUpdateUserLocation: Bool = true
    
    @IBAction func modeMapSegmentedControl(_ sender: UISegmentedControl) {
        guard let _ = scannerMap else {return}
        
        if let modeMap = sender.titleForSegment(at: sender.selectedSegmentIndex) {
            switch modeMap  {
            case "Hybrid":
                scannerMap.mapType = .hybrid
            case "Satellite":
                scannerMap.mapType = .satellite
            default:
                scannerMap.mapType = .standard
            }
        }
    }
    @IBAction func setUserLocationCameraButton(_ sender: UIBarButtonItem) {
        guard let _ = baseLocation else {return}
        guard let _ = scannerMap else {return}
        
        let scannerCamera = MKMapCamera(lookingAtCenter: baseLocation!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
        scannerMap.setCamera(scannerCamera, animated: true)
    }
    @IBOutlet weak var setUserLocationCamera: UIBarButtonItem! {
        didSet {
            setUserLocationCamera.isEnabled = false
        }
    }
    @IBOutlet weak var scannerMap: MKMapView! {
        didSet {
            scannerMap.delegate = self
            scannerMap.showsUserLocation = false
        }
    }
    
    override func viewDidLoad() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        firstUpdateUserLocation = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            if firstUpdateUserLocation {
                pulseActivityIndicator.show(at: scannerMap)
            }
        }
    }
    
    private func getHealthUnitsAroundMe() {
        guard let _ = baseLocation else {return}
        let appCivico = AppCivico()
        let url = appCivico.healthUnitsUrl(AtLatitude: baseLocation!.coordinate.latitude.description, AndLogitude: baseLocation!.coordinate.longitude.description, UnderRadius: "1000")
        let dataTask = URLSession.shared.dataTask(with: url ) {[weak self] (data, response, error) in
            guard let _ = self else {return}
            if error == nil {
                guard let _ = data else {return}
                
                let dataDecoder = JSONDecoder()
                do {
                    let newHealthUnits = try dataDecoder.decode([HealthUnit].self, from: data!)
                    self!.healthUnits.removeAll()
                    self!.healthUnits.append(contentsOf: newHealthUnits)
                    self!.pulseActivityIndicator.hide()
                    self!.plotHealthUnitsInMap()
                }catch {
                    print(error.localizedDescription)
                }
            } else {
                print(error.debugDescription)
                self!.getHealthUnitsAroundMe()
            }
        }
        dataTask.resume()
    }
    
    private func plotHealthUnitsInMap() {
        DispatchQueue.main.async {[weak self] in
            guard let _ = self else {return}
            let oldAnnotations = self!.scannerMap.annotations.filter({(annotation) in return annotation.isKind(of: HealthUnitAnnotation.self)})
            self!.scannerMap.removeAnnotations(oldAnnotations)
            
            for healthUnit in self!.healthUnits {
                let annotation = HealthUnitAnnotation(with: healthUnit)
                self!.scannerMap.addAnnotation(annotation)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "healthUnitDetailSegue" {
            let destinationNatigationController = segue.destination as! UINavigationController
            let destination = destinationNatigationController.viewControllers.first as! HealthUnitDetailViewController
            let annotationView = sender as! MKAnnotationView
            let annotation = annotationView.annotation as! HealthUnitAnnotation
            destination.healthUnit = annotation.healthUnit
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
                annotationView.markerTintColor = annotation.healthUnit.annotationColor()
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegue(withIdentifier: "healthUnitDetailSegue", sender: view)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("*** A região mudou!!! ***")
    }
}

extension ScannerMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("*** Regiões atualizadas... ***")
            baseLocation = locations.last
            if firstUpdateUserLocation {
                firstUpdateUserLocation = false
                let scannerCamera = MKMapCamera(lookingAtCenter: baseLocation!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
                scannerMap.setCamera(scannerCamera, animated: true)
                scannerMap.showsUserLocation = true
                setUserLocationCamera.isEnabled = true
                getHealthUnitsAroundMe()
            }
        }
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("*** Vai começar a atualização!!! ***")
        firstUpdateUserLocation = true
    }
    
}
