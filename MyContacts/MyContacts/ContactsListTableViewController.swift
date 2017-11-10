//
//  ContactsListTableViewController.swift
//  MyContacts
//
//  Created by HC5MAC09 on 09/11/17.
//  Copyright © 2017 IESB - Instituto de Educação Superior de Brasília. All rights reserved.
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
        case .authorized: loadContacts(with: nil)
        case .denied, .notDetermined:
            contactsStore.requestAccess(for: .contacts) {[unowned self] (allowAcess, error) in
                if allowAcess {
                    self.loadContacts(with: nil)
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
        searchController.obscuresBackgroundDuringPresentation = true
        
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }
    private func loadContacts(with criteria: String? ) {
        myContacts.removeAll()
        
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as NSString, CNContactFamilyNameKey as NSString]
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: keys)
        if let _ = criteria, criteria != "" {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: criteria!)
        }

        try? contactsStore.enumerateContacts(with: fetchRequest) { [unowned self] (contact, _) in
            self.myContacts.append(contact)
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
        loadContacts(with: searchController.searchBar.text)
    }
}

extension ContactsListTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadContacts(with: nil)
    }
}
