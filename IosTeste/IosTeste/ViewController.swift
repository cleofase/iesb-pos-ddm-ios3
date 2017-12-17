//
//  ViewController.swift
//  IosTeste
//
//  Created by HC5MAC10 on 25/11/17.
//  Copyright © 2017 IESB. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var loginButton: FBSDKLoginButton! {
        didSet {
            loginButton.delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "didLoginSegue", sender: nil)
        }
    }

}

extension ViewController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let _ = error {
            debugPrint(error.localizedDescription)
        } else {
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            Auth.auth().signIn(with: credential){ (user, error) in
                if let _ = error {
                    debugPrint(error.debugDescription)
                    return
                } else {
                    self.performSegue(withIdentifier: "didLoginSegue", sender: nil)
                    // logado...
                }
                
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Erro ao fazer logooff do Firebase: \(signOutError)")
        }
    }
    
}


