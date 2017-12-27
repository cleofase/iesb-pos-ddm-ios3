//
//  PatientProfileViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 26/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseAuth

class PatientProfileViewController: UIViewController {
    var patient: Patient? {
        didSet {
            updateUI()
        }
    }
    
    private var containter: NSPersistentContainer? = AppDelegate.persistentContainer
    
    @IBOutlet weak var patientNameLabel: UILabel!
    @IBOutlet weak var patientProfilePictureImage: UIImageView! {
        didSet {
            patientProfilePictureImage.layer.cornerRadius = 10
            patientProfilePictureImage.clipsToBounds = true
        }
    }
    
    @IBAction func editProfileButton(_ sender: UIButton) {
        guard let _ = patient else {return}
        performSegue(withIdentifier: "editProfileSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            if let context = containter?.viewContext {
                do {
                    patient = try Patient.findOrCreate(matching: user, in: context)
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editProfileSegue" {
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! EditProfileViewController
            destination.patient = patient
        }
    }
    
    private func updateUI() {
        guard let _ = patient else {return}
        
        patientNameLabel.text = patient!.name
        if let imageData = patient!.profilePicture, let image = UIImage(data: imageData) {
            patientProfilePictureImage.image = image
        }
    }
}
