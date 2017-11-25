//
//  UserDataViewController.swift
//  IosTeste
//
//  Created by HC5MAC10 on 25/11/17.
//  Copyright © 2017 IESB. All rights reserved.
//

import UIKit
import SwiftyFORM
import Firebase

class UserDataViewController: FormViewController {
    private lazy var form: StepperFormItem = {
        let form = StepperFormItem()
        form.title = "Quantidade de Produtos"
        return form
    }()
    
    private lazy var nameField: TextFieldFormItem = {
        let field = TextFieldFormItem()
        field.title = "Nome Completo"
        field.keyboardType = UIKeyboardType.default
        field.returnKeyType = .next
        return field
    }()

    private lazy var emailField: TextFieldFormItem = {
        let field = TextFieldFormItem()
        field.title("E-mail").placeholder = "Entre com o seu e-mail."
        field.keyboardType = UIKeyboardType.emailAddress
        field.submitValidate(EmailSpecification(), message: "E-mail inválido!")
        field.returnKeyType = .next
        return field
    }()
    
    private lazy var phoneField: TextFieldFormItem = {
        let field = TextFieldFormItem()
        field.title = "Telefone"
        field.keyboardType = UIKeyboardType.phonePad
        field.returnKeyType = .next
        return field
    }()
    
    private lazy var bithDateField: DatePickerFormItem = {
        let field = DatePickerFormItem()
        field.title = "Nascimento"
        field.datePickerMode = .date
        field.behavior = .expandedAlways
        return field
    }()
    
    private lazy var submit: ButtonFormItem = {
        let bt = ButtonFormItem()
        bt.title = "Salvar"
        bt.action = {[unowned self] () in
            // pegar os valores dos campos...
            print(self.emailField.value)
            let user = User(userUID: Auth.auth().currentUser!.uid, productCount: self.form.value, name: self.nameField.value, email: self.emailField.value, phone: self.phoneField.value, birthDate: self.bithDateField.value)
            user.persist(withCompletionBlock: {(error, ref) in
                if error == nil {
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Sucesso", message: "Usuário cadastrado com sucesso", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(ac, animated: true, completion: nil)
                    }
                } else {
                    debugPrint(error!)
                }
            })
        }
        return bt
    }()

    override func populate(_ builder: FormBuilder) {
        super.populate(builder)
        builder += SectionHeaderTitleFormItem().title("Complete seu cadastro")
        builder += form
        builder += nameField
        builder += emailField
        builder += phoneField
        builder += bithDateField
        builder += submit



    }
}
