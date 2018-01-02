//
//  ScannerMapViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 17/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation
import FirebaseCore
import FirebaseAuth
import UserNotifications

class ScannerMapViewController: UIViewController {
    var baseLocation: CLLocation?
    var healthUnits = [HealthUnit]()
    
    private var containter: NSPersistentContainer? = AppDelegate.persistentContainer
    private var locationManager = CLLocationManager()
    private var pulseActivityIndicator = PulseActivityIndicator()
    private var pendingUpdateUnitsAround: Bool = true
    private var handle: AuthStateDidChangeListenerHandle?
    
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
            scannerMap.showsUserLocation = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        pendingUpdateUnitsAround = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handle = Auth.auth().addStateDidChangeListener({(auth, user) in
            if let _ = user {} else {
                let mainStoryBorad = UIStoryboard(name: "Main", bundle: nil)
                let initialViewController = mainStoryBorad.instantiateInitialViewController()
                UIApplication.shared.keyWindow?.rootViewController = initialViewController
            }
        })
        
        locationManager.startUpdatingLocation()

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            if pendingUpdateUnitsAround {
                pulseActivityIndicator.show(at: scannerMap)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
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
        let healUnitOptionsAlert = UIAlertController(title: "Heal Unit Options", message: "Choose the desired action", preferredStyle: .actionSheet)
        healUnitOptionsAlert.addAction(UIAlertAction(title: "Detail", style: .default, handler: {[unowned self](action) in
            self.performSegue(withIdentifier: "healthUnitDetailSegue", sender: view)
        }))
        healUnitOptionsAlert.addAction(UIAlertAction(title: "Check In", style: .default, handler: {[unowned self](action) in
            let annotation = view.annotation as! HealthUnitAnnotation
            let unit = annotation.healthUnit

            if let context = self.containter?.viewContext {
                do {
                    if let patient = try Patient.find(matching: Auth.auth().currentUser!.uid, in: context) {
                        let visit = try Visit.createOrUpdate(in: context, withPatient: patient, healthUnitId: unit.codUnidade!, regionInTime: Date(),regionOutTime: Date())
                        visit.healthUnitName = unit.nomeFantasia
                        visit.healthUnitDescription = unit.descricaoCompleta
                        visit.checkedIn = true
                        try context.save()
                    }
                } catch {
                    print("Error performing manual check in: \(error.localizedDescription)")
                }
            }
            
        }))
        healUnitOptionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(healUnitOptionsAlert, animated: true, completion: nil)
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
}

extension ScannerMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let _ = Auth.auth().currentUser else {return}
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            baseLocation = locations.last
            if pendingUpdateUnitsAround {
                pendingUpdateUnitsAround = false
                getHealthUnits(around: baseLocation!) {[unowned self](units) in
                    self.healthUnits = units
                    self.updateRegions(withHealthUnits: units)
                    self.plotHealthUnitsInMap()
                    self.pulseActivityIndicator.hide()
                }

                let scannerCamera = MKMapCamera(lookingAtCenter: baseLocation!.coordinate, fromDistance: 1000, pitch: 0, heading: 0)
                scannerMap.setCamera(scannerCamera, animated: true)
                setUserLocationCamera.isEnabled = true

                if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                    let patientRegion = CLCircularRegion(center: baseLocation!.coordinate, radius: 100, identifier: Auth.auth().currentUser!.uid)
                    patientRegion.notifyOnExit = true
                    locationManager.startMonitoring(for: patientRegion)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let _ = Auth.auth().currentUser else {return}
        
        let units = healthUnits.filter({(healthUnit) in return healthUnit.codUnidade == region.identifier})
        if units.count > 0 {
            let unit = units.first
            if let context = containter?.viewContext {
                do {
                    if let patient = try Patient.find(matching: Auth.auth().currentUser!.uid, in: context) {
                        let visit = try Visit.createOrUpdate(in: context, withPatient: patient, healthUnitId: unit!.codUnidade!, regionInTime: Date())
                        visit.healthUnitName = unit!.nomeFantasia
                        visit.healthUnitDescription = unit!.descricaoCompleta!
                        try context.save()
                    }
                } catch {
                    print("Error in LocationManagerDidEnterRegion: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let _ = Auth.auth().currentUser else {return}
        
        if region.identifier == Auth.auth().currentUser!.uid {
            locationManager.stopMonitoring(for: region)
            pendingUpdateUnitsAround = true
            return
        }
        
        if healthUnits.filter({(healthUnit) in return healthUnit.codUnidade == region.identifier}).count > 0 {
            if let context = containter?.viewContext {
                do {
                    if let patient = try Patient.find(matching: Auth.auth().currentUser!.uid, in: context) {
                        let _ = try Visit.createOrUpdate(in: context, withPatient: patient, healthUnitId: region.identifier, regionOutTime: Date())
                        try context.save()
                    }
                } catch {
                    print("Error in LocationManagerDidExitRegion: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getHealthUnits(around location: CLLocation, handle completion: @escaping (_: [HealthUnit]) -> Void ) {
        let appCivico = AppCivico()
        let url = appCivico.healthUnitsUrl(AtLatitude: location.coordinate.latitude.description, AndLogitude: location.coordinate.longitude.description, UnderRadius: "500")
        let dataTask = URLSession.shared.dataTask(with: url ) {[weak self] (data, response, error) in
            guard let _ = self else {return}
            if error == nil {
                var units = [HealthUnit]()
                guard let _ = data else {return}
                
                let dataDecoder = JSONDecoder()
                do {
                    let newHealthUnits = try dataDecoder.decode([HealthUnit].self, from: data!)
                    units.append(contentsOf: newHealthUnits)
                    completion(units)
                }catch {
                    print(error.localizedDescription)
                }
            } else {
                print(error.debugDescription)
                self!.getHealthUnits(around: self!.baseLocation!, handle: completion)
            }
        }
        dataTask.resume()
    }
    
    private func updateRegions(withHealthUnits healthUnits: [HealthUnit]) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {return}
        
        for healthUnit in healthUnits {
            let alreadyCreatedRegion = locationManager.monitoredRegions.filter({(region) in return region.identifier == healthUnit.codUnidade!})
            guard alreadyCreatedRegion.count == 0 else {continue}
            
            let regionId = healthUnit.codUnidade!
            let regionCenter = CLLocationCoordinate2DMake(healthUnit.lat!, healthUnit.long!)
            
            let newRegion = CLCircularRegion(center: regionCenter, radius: 20, identifier: regionId)
            newRegion.notifyOnEntry = true
            newRegion.notifyOnExit = true
            locationManager.startMonitoring(for: newRegion)
            
            if AppDelegate.notificationGranted {
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = "Cnes App - Unit Health nearby"
                notificationContent.body = "The Unit Heath \(healthUnit.nomeFantasia!) is near"
                
                let notificationTrigger = UNLocationNotificationTrigger(region: newRegion, repeats: false)
                
                let request = UNNotificationRequest(identifier: healthUnit.codUnidade!, content: notificationContent, trigger: notificationTrigger)
                
                let center = UNUserNotificationCenter.current()
                center.add(request, withCompletionHandler: {(error) in if error == nil {print("add notification successfully")}})
            }
        }
    }
}
