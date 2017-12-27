//
//  HealthUnitDetailViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 27/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import MapKit

class HealthUnitDetailViewController: UIViewController {
    var healthUnit: HealthUnit?
    
    
    @IBOutlet weak var healthUnitMap: MKMapView!
    @IBOutlet weak var healthUnitNameLabel: UILabel!
    @IBOutlet weak var healthUnitDescriptionLabel: UILabel!
    @IBAction func closeHealthUnitDetailButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    private func updateUI() {
        guard let _ = healthUnit else {return}
        
        healthUnitNameLabel.text = healthUnit!.nomeFantasia
        healthUnitDescriptionLabel.text = healthUnit!.descricaoCompleta
        let healthUnitLocation = CLLocationCoordinate2DMake(healthUnit!.lat!, healthUnit!.long!)
        let camera = MKMapCamera(lookingAtCenter: healthUnitLocation, fromDistance: 100, pitch: 0, heading: 0)
        let annotation = HealthUnitAnnotation(with: healthUnit!)
        healthUnitMap.setCamera(camera, animated: true)
        healthUnitMap.addAnnotation(annotation)
    }
}
