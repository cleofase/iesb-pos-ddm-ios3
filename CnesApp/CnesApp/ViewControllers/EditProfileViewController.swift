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
import FirebaseDatabase

class EditProfileViewController: UIViewController {
    var patient: Patient?
    private var container: NSPersistentContainer? = AppDelegate.persistentContainer
    private var firebaseDatabaseReference = Database.database().reference()
    private var topConstraintConstant: CGFloat?
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldsStackView: UIStackView!
    
    
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
    
    @IBAction func editProfilePhotoButton(_ sender: UIButton) {
        pickImage()
    }
    
    @IBAction func cancelEditProfileButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func saveEditProfileButton(_ sender: UIBarButtonItem) {
        guard let _ = patient else {return}
        
        if let patientName = patientNameText.text, patientName.count > 0 {} else {
            let emptyNameFieldAlert = UIAlertController(title: "Patient Name", message: "Please, enter your name.", preferredStyle: .alert)
            emptyNameFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  {[unowned self] _ in
                self.patientNameText.becomeFirstResponder()
                self.patientNameText.text?.removeAll()
            }))
            self.present(emptyNameFieldAlert, animated: true, completion: nil)
            return
        }
        
        if let patientMail = patientEmailText.text, patientMail.count > 0 {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            if !NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: patientMail) {
                let invalidEmailFieldAlert = UIAlertController(title: "Email", message: "Please, enter your email.", preferredStyle: .alert)
                invalidEmailFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  {[unowned self] _ in
                    self.patientEmailText.becomeFirstResponder()
                    self.patientEmailText.text?.removeAll()
                }))
                self.present(invalidEmailFieldAlert, animated: true, completion: nil)
                return
            }
        } else {
            let emptyEmailFieldAlert = UIAlertController(title: "Email", message: "Please, enter your email.", preferredStyle: .alert)
            emptyEmailFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  {[unowned self] _ in
                self.patientEmailText.becomeFirstResponder()
                self.patientEmailText.text?.removeAll()
            }))
            self.present(emptyEmailFieldAlert, animated: true, completion: nil)
            return
        }
        
        self.patient!.name = self.patientNameText.text
        self.patient!.email = self.patientEmailText.text
        if let _ = self.patientProfilePhotoImage.image {
            self.patient!.profilePicture = UIImagePNGRepresentation(self.patientProfilePhotoImage.image!)
        }
        do {
            try container?.viewContext.save()
        } catch {
            let saveErrorAlert = UIAlertController(title: "Save Profile", message: "\(error.localizedDescription) Please try again later.", preferredStyle: .alert)
            saveErrorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        }
        print(patient!.name!)
        firebaseDatabaseReference.child("patients").child(patient!.patientId!).setValue(patient!.dictionaryValue())
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topConstraintConstant = topConstraint.constant
        
        if let _ = patient {
            patientEmailText.text = patient!.email
            patientNameText.text = patient!.name
            if let photoData = patient!.profilePicture, let profilePhoto = UIImage(data: photoData) {
                patientProfilePhotoImage.image = profilePhoto
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startObserveKeyboardEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObserveKeyboardEvents()
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
    
    private func startObserveKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(_:)), name: Notification.Name.UIKeyboardWillShow, object: view.window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidDisappear(_:)), name: Notification.Name.UIKeyboardWillHide, object: view.window)
    }
    
    private func stopObserveKeyboardEvents() {
         NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardDidAppear(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            let delta = view.bounds.maxY - fieldsStackView.frame.maxY - keyboardFrame.size.height - 16
            if delta < 0 {
                topConstraint.constant = topConstraintConstant! + delta
            }
        }
    }
    
    @objc private func keyboardDidDisappear(_ notification: Notification) {
        topConstraint.constant = topConstraintConstant!
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            patientProfilePhotoImage.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
        patientProfilePhotoImage.gestureRecognizers!.filter({(gestureRecognizer) -> Bool in return gestureRecognizer.isKind(of: UITapGestureRecognizer.self)}).forEach({(gestureRecognizer) in gestureRecognizer.isEnabled = true})
    }
}
