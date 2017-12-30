//
//  EmailLogInViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 23/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseAuth


class EmailLogInViewController: UIViewController {
    private var stackViewBottomConstant: CGFloat?
    private var container: NSPersistentContainer? = AppDelegate.persistentContainer
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var userEmailText: UITextField! {didSet{userEmailText.delegate = self}}
    @IBOutlet weak var userPasswordText: UITextField! {didSet{userPasswordText.delegate = self}}
    @IBAction func cancelEmailSignUpButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func proceedEmailLogInButton(_ sender: UIBarButtonItem) {
        if let userMail = userEmailText.text, userMail.count > 0 {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            if !NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: userMail) {
                let invalidEmailFieldAlert = UIAlertController(title: "Email", message: "Please, enter your account email.", preferredStyle: .alert)
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
        
        if let userPassword = userPasswordText.text, userPassword.count > 0 {} else {
            let emptyPasswordFieldAlert = UIAlertController(title: "Password", message: "Please, enter your password.", preferredStyle: .alert)
            emptyPasswordFieldAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned self] _ in
                self.userPasswordText.becomeFirstResponder()
                self.userPasswordText.text?.removeAll()
            }))
            self.present(emptyPasswordFieldAlert, animated: true, completion: nil)
            return
        }
        
        Auth.auth().signIn(withEmail: userEmailText.text!, password: userPasswordText.text!) {[unowned self] (user, error) in
            if error != nil {
                let logInErrorAlert = UIAlertController(title: "Log In", message: "Error trying log in: \(error!.localizedDescription) Please, try again.", preferredStyle: .alert)
                logInErrorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(logInErrorAlert, animated: true, completion: nil)
            } else {
                if user!.isEmailVerified {
                    // salvar usuário no CoreData
                    DispatchQueue.main.async {[weak self] in
                        if let context = self?.container?.viewContext {
                            do {
                                if try Patient.find(matching: user!.uid, in: context) == nil {
                                    _ = try Patient.create(with: user!, in: context)
                                    try context.save()
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    
                    Auth.auth().currentUser?.getIDToken() { (token, error) in
                        if error == nil {
                            UserDefaults.standard.setValue(token, forKey: "userToken")
                        }
                    }
                    self.dismiss(animated: true, completion: nil)
                } else {
                    let emailNotVerifiedAlert = UIAlertController(title: "Log In", message: "Your email is pending verification. Please check your email and verify your account.", preferredStyle: .alert)
                    emailNotVerifiedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(emailNotVerifiedAlert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func forgotPasswordButton(_ sender: UIButton) {
        let forgotPasswordAlert = UIAlertController(title: "Forgot password?", message: "Please, enter your email here.", preferredStyle: .alert)
        forgotPasswordAlert.addTextField() {textField in textField.placeholder = "Enter your email"}
        forgotPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        forgotPasswordAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(alertAction) in
            if let emailText = forgotPasswordAlert.textFields?.first?.text {
                Auth.auth().sendPasswordReset(withEmail: emailText) {[unowned self] (error) in
                    if error != nil {
                        let sendResetFailedAlert = UIAlertController(title: "Reset password", message: "\(error!.localizedDescription) Please try again later.", preferredStyle: .alert)
                        sendResetFailedAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(sendResetFailedAlert, animated: true, completion: nil)
                    } else {
                        let resetEmailSentAlert = UIAlertController(title: "Reset password", message: "A password reset email has been sent. Please check your email to instructions", preferredStyle: .alert)
                        resetEmailSentAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(resetEmailSentAlert, animated: true, completion: nil)
                    }
                }
            } else {
                // empty email field...
            }
        }))
        self.present(forgotPasswordAlert, animated: true, completion: nil)
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

extension EmailLogInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userEmailText {
            userPasswordText.becomeFirstResponder()
            return true
        }
        
        view.endEditing(true)
        return true
    }
    
}
