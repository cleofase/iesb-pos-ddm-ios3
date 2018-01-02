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
    var healthUnit: HealthUnit? {
        didSet {
            if let _ = healthUnit {
                healthUnitDictionary = healthUnit!.dictionaryValue()
            }
        }
    }
    private var healthUnitDictionary: [String: Array<String>]?
    
    
    @IBOutlet weak var healthUnitMap: MKMapView! {
        didSet {
            healthUnitMap.mapType = .satellite
        }
    }
    @IBOutlet weak var healthUnitNameLabel: UILabel!
    @IBOutlet weak var healthUnitDescriptionLabel: UILabel!
    @IBOutlet weak var healthUnitDetailTable: UITableView! {
        didSet {
            healthUnitDetailTable.dataSource = self
        }
    }
    
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

extension HealthUnitDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let dictionaryKeys = [String](healthUnitDictionary!.keys)
        return dictionaryKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dictionaryKeys = [String](healthUnitDictionary!.keys)
        let arrayValue = healthUnitDictionary![dictionaryKeys[section]]
        return arrayValue?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseHealthUnitDetailCell", for: indexPath)
        let dictionaryKeys = [String](healthUnitDictionary!.keys)
        let arrayValue = healthUnitDictionary![dictionaryKeys[indexPath.section]]
        cell.textLabel?.text = arrayValue![indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dictionaryKeys = [String](healthUnitDictionary!.keys)
        return dictionaryKeys[section]
    }
    
}
