//
//  AuthenticationViewController.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 28/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class AuthenticationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "logedInSegue", sender: self)
        }
    }


}
