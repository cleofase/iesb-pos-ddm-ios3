//
//  EditProfileViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 26/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import Photos
import CoreData
import FirebaseCore
import FirebaseAuth

class EditProfileViewController: UIViewController {
    var patient: Patient?
    private var container: NSPersistentContainer? = AppDelegate.persistentContainer
    
    @IBOutlet weak var patientProfilePhotoImage: UIImageView! {
        didSet {
            patientProfilePhotoImage.layer.cornerRadius = 10
            patientProfilePhotoImage.clipsToBounds = true
            
            patientProfilePhotoImage.gestureRecognizers?.filter({(gestureRecognizer) in return gestureRecognizer.isKind(of: UITapGestureRecognizer.self)}).forEach{[unowned self] (gestureRecognizer) in self.patientProfilePhotoImage.removeGestureRecognizer(gestureRecognizer)
            }
            
            let profilePictureTapGesture = UITapGestureRecognizer(target: self, action: #selector(editProfilePhoto(_:)))
            patientProfilePhotoImage.addGestureRecognizer(profilePictureTapGesture)
        }
    }
    @IBOutlet weak var patientNameText: UITextField!
    @IBOutlet weak var patientEmailText: UITextField!
    @IBOutlet weak var patientPhoneText: UITextField!
    
    @IBAction func editProfilePhotoButton(_ sender: UIButton) {
        pickImage()
    }
    
    @IBAction func cancelEditProfileButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func saveEditProfileButton(_ sender: UIBarButtonItem) {
        container?.performBackgroundTask {[unowned self] context in
            self.patient?.profilePicture = UIImagePNGRepresentation(self.patientProfilePhotoImage.image!)
            try? context.save()
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        patientEmailText.text = patient?.email
        patientNameText.text = patient?.name
        

    }
    
    @objc func editProfilePhoto(_ sender: UITapGestureRecognizer) {
        sender.isEnabled = false
        pickImage()
    }
    
    private func pickImage() {
        let pickImageAlert = UIAlertController(title: "Edit Photo", message: "Select your photo's source", preferredStyle: .actionSheet)
        pickImageAlert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[unowned self] (action) in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = .photoLibrary
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            self.present(picker, animated: true, completion: nil)
        }))
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            pickImageAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[unowned self] (action) in
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.allowsEditing = true
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }))
        }
        pickImageAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(pickImageAlert, animated: true, completion: nil)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            patientProfilePhotoImage.image = pickedImage
            
        }
        picker.dismiss(animated: true, completion: nil)
        patientProfilePhotoImage.gestureRecognizers!.filter({(gesture) -> Bool in return gesture.isKind(of: UITapGestureRecognizer.self)}).forEach({(gesture) in gesture.isEnabled = true})
    }
}
