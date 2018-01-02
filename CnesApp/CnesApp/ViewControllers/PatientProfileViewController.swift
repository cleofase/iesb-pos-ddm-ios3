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
import FirebaseDatabase

class PatientProfileViewController: UIViewController {
    var patient: Patient?
    var patientCheckIns: [Visit]?
    
    private var containter: NSPersistentContainer? = AppDelegate.persistentContainer
    private var handle: AuthStateDidChangeListenerHandle?
    private var firebaseDatabaseReference = Database.database().reference()

    
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
    
    @IBOutlet weak var checkInsTable: UITableView! {
        didSet {
            checkInsTable.dataSource = self
            checkInsTable.delegate = self
        }
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
        updateDatabase()
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
    
    private func updateDatabase() {
        firebaseDatabaseReference.child("patients").child(patient!.patientId!).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
            if let patientDictionary = snapshot.value as? NSDictionary {
                if let patientName = patientDictionary["name"] as? String {
                    if let context = self.containter?.viewContext {
                        do {
                            self.patient!.name = patientName
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }

                }
                if let patientEmail = patientDictionary["email"] as? String {
                    if let context = self.containter?.viewContext {
                        do {
                            self.patient!.email = patientEmail
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                DispatchQueue.main.async {[unowned self] in
                    self.updateUI()
                }
            }
        }
    }
    
    private func updateUI() {
        guard let _ = patient else {return}
        
        patientNameLabel.text = patient!.name
        patientEmailLabel.text = patient!.email
        if let imageData = patient!.profilePicture, let image = UIImage(data: imageData) {
            patientProfilePictureImage.image = image
        }
        
        patientCheckInLabel.text = checkInCount(withPatient: patient!).description
        getCheckIns()
    }
    
    private func getCheckIns() {
        if let context = containter?.viewContext {
            do {
                patientCheckIns = try Visit.find(in: context, matchingPatientId: patient!.patientId!)
            } catch {
                print(error.localizedDescription)
            }
        }
        checkInsTable.reloadData()
    }
    
    private func performCheckIn(atVisit visit: Visit) {
        if let context = containter?.viewContext {
            do {
                visit.checkedIn = true
                try context.save()
                checkInsTable.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func checkInCount(withPatient patient: Patient) -> Int {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "checkedIn == true AND patient.patientId = %@", patient.patientId ?? "")
        return (try? patient.managedObjectContext!.count(for: request)) ?? 0
    }
}

extension PatientProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patientCheckIns?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCheckInCell", for: indexPath)
        cell.textLabel?.text = patientCheckIns![indexPath.row].healthUnitName
        cell.detailTextLabel?.text = patientCheckIns![indexPath.row].healthUnitDescription
        if patientCheckIns![indexPath.row].checkedIn {
            cell.textLabel?.textColor = UIColor(named: "green_black")
            cell.detailTextLabel?.textColor = UIColor(named: "green_black")
        }
        return cell
    }
    
}

extension PatientProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if !patientCheckIns![indexPath.row].checkedIn {
            let checkInAction = UITableViewRowAction(style: .default, title: "Check In", handler: {[unowned self](action, indexPath) in
                self.performCheckIn(atVisit: self.patientCheckIns![indexPath.row])
            })
            return[checkInAction]
        }
        return []
    }
    
}
