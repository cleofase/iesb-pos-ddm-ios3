//
//  ContactsListTableViewController.swift
//  MyContacts
//
//  Created by Cleofas Pereira on 11/11/17.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ContactsListTableViewController: UITableViewController {
    var myContacts = [CNContact]()
    let contactsStore = CNContactStore()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBAction func addContactButton(_ sender: UIBarButtonItem) {
        let contactViewController = CNContactViewController(forNewContact: nil)
        contactViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: contactViewController)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.modalTransitionStyle = .flipHorizontal
        
        present(navigationController, animated: true, completion: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch authorizationStatus {
        case .authorized: loadContacts()
        case .denied, .notDetermined:
            contactsStore.requestAccess(for: .contacts) {[unowned self] (allowAcess, error) in
                if allowAcess {
                    self.loadContacts()
                } else {
                    print("No acess granted")
                }
                
            }
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Pesquisar Contatos"
        searchController.searchBar.scopeButtonTitles = ["Nome","Sobrenome"]
        searchController.obscuresBackgroundDuringPresentation = true
        
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }
    private func loadContacts(with criteria: String? = nil, andScope scope: String? = nil) {
        var scopePredicate: NSPredicate? = nil
        myContacts.removeAll()
        
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as NSString, CNContactFamilyNameKey as NSString]
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: keys)
        if let _ = criteria, criteria != "" {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: criteria!)
            if let _ = scope, scope != "" {
                switch scope! {
                case "Nome": scopePredicate = NSPredicate(format: "givenName contains[cd] %@", criteria!)
                case "Sobrenome": scopePredicate = NSPredicate(format: "familyName contains[cd] %@", criteria!)
                default: break
                }
            }
        }
        
        try? contactsStore.enumerateContacts(with: fetchRequest) { [unowned self] (contact, _) in
            self.myContacts.append(contact)
        }
        
        if let _ = scopePredicate {
            self.myContacts = self.myContacts.filter {
                scopePredicate!.evaluate(with: $0)
            }
        }
        
        DispatchQueue.main.async {[unowned self] in
            self.tableView.reloadData()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myContacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseContactCell", for: indexPath)
        cell.textLabel?.text = myContacts[indexPath.row].givenName
        cell.detailTextLabel?.text = myContacts[indexPath.row].familyName
        
        return cell
    }
}

extension ContactsListTableViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
}

extension ContactsListTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let criteria = searchController.searchBar.text
        let scope = searchController.searchBar.scopeButtonTitles![searchController.searchBar.selectedScopeButtonIndex]
        loadContacts(with: criteria, andScope: scope)
    }
}

extension ContactsListTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadContacts(with: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let criteria = searchBar.text
        let scope = searchBar.scopeButtonTitles![selectedScope]
        loadContacts(with: criteria, andScope: scope)
    }
    

}
