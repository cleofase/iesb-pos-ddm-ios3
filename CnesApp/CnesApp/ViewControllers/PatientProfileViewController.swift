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
    private var handle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var patientNameLabel: UILabel!
    @IBOutlet weak var patientEmailLabel: UILabel!
    @IBOutlet weak var patientCheckInLabel: UILabel!
    
    
    @IBOutlet weak var patientProfilePictureImage: UIImageView! {
        didSet {
            patientProfilePictureImage.layer.cornerRadius = 10
            patientProfilePictureImage.clipsToBounds = true
        }
    }
    
    @IBAction func profileOptionsButton(_ sender: UIBarButtonItem) {
        guard let _ = patient else {return}
        
        let profileOptionsAlert = UIAlertController(title: "Profile options", message: "Choice the desired action to your profile.", preferredStyle: .actionSheet)
        profileOptionsAlert.addAction(UIAlertAction(title: "Edit Profile", style: .default, handler: {[unowned self](_) in
            self.performSegue(withIdentifier: "editProfileSegue", sender: self)
        }))
        profileOptionsAlert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: {[unowned self](_) in
            do {
                try Auth.auth().signOut()
            } catch {
                let signOutErrorAlert = UIAlertController(title: "Sign Out", message: "\(error.localizedDescription) Please try again later.", preferredStyle: .alert)
                signOutErrorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(signOutErrorAlert, animated: true, completion: nil)
            }
        }))
        profileOptionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(profileOptionsAlert, animated: true, completion: nil)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener({(auth, user) in
            if let _ = user {} else {
                let mainStoryBorad = UIStoryboard(name: "Main", bundle: nil)
                let initialViewController = mainStoryBorad.instantiateInitialViewController()
                UIApplication.shared.keyWindow?.rootViewController = initialViewController
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
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
        patientEmailLabel.text = patient!.email
        if let imageData = patient!.profilePicture, let image = UIImage(data: imageData) {
            patientProfilePictureImage.image = image
        }
    }
}
