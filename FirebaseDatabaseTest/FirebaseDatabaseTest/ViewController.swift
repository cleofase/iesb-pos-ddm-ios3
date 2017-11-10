//
//  ViewController.swift
//  FirebaseDatabaseTest
//
//  Created by Cleofas Pereira on 07/11/17.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var nameProductTextField: UITextField!
    @IBOutlet weak var descriptionProductTextField: UITextField!
    @IBAction func addProductButton(_ sender: UIButton) {
        guard let nameProduct = nameProductTextField.text else {return}
        guard let descriptionProduct = descriptionProductTextField.text else {return}
        
        //let newProduct = Product(name: nameProduct, description: descriptionProduct)
        //let jsonEnconder = JSONEncoder()
        //let newProductData = try? jsonEnconder.encode(newProduct)
        //rootRef.child("produto").childByAutoId().setValue(String(data: newProductData!, encoding: String.Encoding.utf8))
        
        let newProduct = ["name": nameProduct ,"description": descriptionProduct]
        rootRef.child("produto").childByAutoId().setValue(newProduct)
        }
    
    
    
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBAction func manualStatusButton(_ sender: UIButton) {
    }
    @IBAction func automaticoStatusButton(_ sender: UIButton) {
    }
    
    let rootRef = Database.database().reference()
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        let modalidadeRef = rootRef.child("produto")
        modalidadeRef.observe(.value) {snap in
            var produtos: [Product]?
            let jsonDecoder = JSONDecoder()
            produtos = try? jsonDecoder.decode([Product].self, from: snap.value as! Data)
            guard let _ = produtos else {return}
            for produto in produtos! {
                print(produto.name)
                print(produto.description)
            }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

