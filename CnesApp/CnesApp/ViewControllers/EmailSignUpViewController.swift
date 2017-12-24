//
//  EmailSignUpViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 23/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class EmailSignUpViewController: UIViewController {
    private var stackViewBottomConstant: CGFloat?
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var userEmailText: UITextField! {didSet{userEmailText.delegate = self}}
    @IBOutlet weak var userPasswordText: UITextField! {didSet{userPasswordText.delegate = self}}
    @IBOutlet weak var userRePasswordText: UITextField! {didSet{userRePasswordText.delegate = self}}
    @IBAction func cancelEmailSignUpButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func proceedEmailSignUpButton(_ sender: UIBarButtonItem) {
        if let email = userEmailText.text, email.count > 0 {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            if !NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email) {
                let invalidEmailFieldAlert = UIAlertController(title: "Email", message: "Please, enter a valid account email.", preferredStyle: .alert)
                invalidEmailFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  {[unowned self] _ in
                    self.userEmailText.becomeFirstResponder()
                    self.userEmailText.text?.removeAll()
                }))
                self.present(invalidEmailFieldAlert, animated: true, completion: nil)
                return
            }
        } else {
            let emptyEmailFieldAlert = UIAlertController(title: "Email", message: "Please, enter your account email.", preferredStyle: .alert)
            emptyEmailFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:  {[unowned self] _ in
                self.userEmailText.becomeFirstResponder()
                self.userEmailText.text?.removeAll()
            }))
            self.present(emptyEmailFieldAlert, animated: true, completion: nil)
            return
        }
        
        if let passWord = userPasswordText.text, passWord.count > 0 {} else {
            let emptyPasswordFieldAlert = UIAlertController(title: "Password", message: "Please, enter your password.", preferredStyle: .alert)
            emptyPasswordFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned self] _ in
                self.userPasswordText.becomeFirstResponder()
                self.userPasswordText.text?.removeAll()
            }))
            self.present(emptyPasswordFieldAlert, animated: true, completion: nil)
            return
        }

        if let rePassWord = userRePasswordText.text, rePassWord.count > 0 {
            if userPasswordText.text != userRePasswordText.text {
                let invalidRePasswordFieldAlert = UIAlertController(title: "Password", message: "Your passwords do not match. Please, reenter your password again.", preferredStyle: .alert)
                invalidRePasswordFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned self] _ in
                    self.userRePasswordText.becomeFirstResponder()
                    self.userRePasswordText.text?.removeAll()
                }))
                self.present(invalidRePasswordFieldAlert, animated: true, completion: nil)
                return
            }
        } else {
            let emptyRePasswordFieldAlert = UIAlertController(title: "Password", message: "Please, reenter your password again.", preferredStyle: .alert)
            emptyRePasswordFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned self] _ in
                self.userRePasswordText.becomeFirstResponder()
                self.userRePasswordText.text?.removeAll()
            }))
            self.present(emptyRePasswordFieldAlert, animated: true, completion: nil)
            return
        }
        
        Auth.auth().createUser(withEmail: userEmailText.text!, password: userPasswordText.text!) {[unowned self] (user, error) in
            if error != nil {
                let signUpErrorAlert = UIAlertController(title: "Sign Up", message: "\(error!.localizedDescription) Please try again later.", preferredStyle: .alert)
                signUpErrorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(signUpErrorAlert, animated: true, completion: nil)
            } else {
                self.sendEmailVerification()
            }
        }
    }
    
    private func sendEmailVerification() {
        Auth.auth().signIn(withEmail: userEmailText.text!, password: userPasswordText.text!) {[unowned self] (user, error) in
            if error != nil {
                let signUpErrorAlert = UIAlertController(title: "Sign Up", message: "\(error!.localizedDescription) Please try again later.", preferredStyle: .alert)
                signUpErrorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(signUpErrorAlert, animated: true, completion: nil)
            } else {
                Auth.auth().currentUser?.sendEmailVerification() {[unowned self] (error) in
                    if error != nil {
                        let emailVerificationNotSendAlert = UIAlertController(title: "Email Verification", message: "\(error!.localizedDescription) Please try again later.", preferredStyle: .alert)
                        emailVerificationNotSendAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(emailVerificationNotSendAlert, animated: true, completion: nil)
                    } else {
                        let emailVerificationSendAlert = UIAlertController(title: "Email Verification", message: "Verification email has been sent, please tap on the link in email to verify you account before you Log In.", preferredStyle: .alert)
                        emailVerificationSendAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned self] _ in self.dismiss(animated: true, completion: nil) }))
                        self.present(emailVerificationSendAlert, animated: true, completion: nil)
                    }
                }
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Error signing out after try sent email verification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackViewBottomConstant = bottomConstraint.constant
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(_:)), name: Notification.Name.UIKeyboardWillShow, object: view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidDisappear(_:)), name: Notification.Name.UIKeyboardWillHide, object: view.window)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardDidAppear(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            bottomConstraint.constant = stackViewBottomConstant! + keyboardFrame.size.height
        }
    }
    
    @objc private func keyboardDidDisappear(_ notification: Notification) {
        bottomConstraint.constant = stackViewBottomConstant!
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
}

extension EmailSignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userEmailText {
            userPasswordText.becomeFirstResponder()
            return true
        }
        
        if textField == userPasswordText {
            userRePasswordText.becomeFirstResponder()
            return true
        }
        
        view.endEditing(true)
        return true
    }
    
}
