//
//  DSSListViewController.swift
//  DSSToDoListApp
//
//  Created by David on 03/02/22.
//

import UIKit
import Parse

extension DSSToDoListItemModel {
    init?(_ pfObject: PFObject) {
        guard let id = pfObject.objectId,
              let title = pfObject["title"] as? String,
              let description = pfObject["description"] as? String else {
            return nil
        }
        
        self.init(id: id, title: title, description: description)
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let backAction = UIAlertAction(title: "Back", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
                
        alertController.addAction(backAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

class DSSListViewController: UITableViewController {
    private var models: [DSSToDoListItemModel] = []
    
    private var accountManager: DSSAccountManager { .shared }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "To do list".uppercased()
        
        setupNavigationBar()
        
        setupTableView()
    }
    
    private func setupNavigationBar() {
        if accountManager.user == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sign up", style: .plain, target: self, action: #selector(signUp))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log in", style: .plain, target: self, action: #selector(logIn))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(logOut))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
        }
    }
    
    private func setupTableView() {
        tableView.register(DSSToDoItemCell.self, forCellReuseIdentifier: DSSToDoItemCell.id)
        tableView.tableFooterView = .init()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchItems()
    }
}

// MARK: - Parse logic
extension DSSListViewController {
    private func fetchItems() {
        guard let userId = accountManager.user?.objectId else { return }
        let predicate = NSPredicate(format: "userId = %@", userId)
        let query: PFQuery = PFQuery(className: Environment.ServerClass.toDoList, predicate: predicate)
        
        query.findObjectsInBackground { [weak self] objects, error in
            if let error = error {
                return print("Failed tofetch items with error: \(error.localizedDescription)")
            }
            
            guard let objects = objects else {
                return print("Failed to unwrap objects.")
            }
            self?.models = objects.compactMap(DSSToDoListItemModel.init)
            
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }
    }
    
    @objc private func addNewItem() {
        enum ItemDescription: Int { case title = 0, description = 1 }
        guard let userId = accountManager.user?.objectId else { return }
        
        let addItemAlertController = UIAlertController(title: "New item", message: "Write a description for the item", preferredStyle: .alert)
        addItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.title.rawValue
            textField.placeholder = "Title"
        }
        
        addItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.description.rawValue
            textField.placeholder = "Description"
        }
        
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] action in
            guard let title = addItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.title.rawValue })?.text,
                  let description = addItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.description.rawValue })?.text else {
                return addItemAlertController.dismiss(animated: true, completion: nil)
            }
            
            self?.saveItem(userId: userId, title: title, description: description) {
                addItemAlertController.dismiss(animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            addItemAlertController.dismiss(animated: true, completion: nil)
        }
        
        addItemAlertController.addAction(addAction)
        addItemAlertController.addAction(cancelAction)
        
        present(addItemAlertController, animated: true, completion: nil)
    }
    
    private func saveItem(userId: String, title: String, description: String, completion: @escaping () -> Void) {
        let object = PFObject(className: Environment.ServerClass.toDoList)
        
        object["userId"] = userId
        object["title"] = title
        object["description"] = description
        
        object.saveInBackground { [weak self] success, error in
            guard let self = self else { return }
            guard success else {
                print("Failed to save in background")
                return completion()
            }
            
            if let error = error {
                print("Failed to save in background with error: \(error.localizedDescription)")
                return completion()
            }
            
            print("Saved inbackground! ObjectId: \(object.objectId ?? "N/A")")
            self.models.append(DSSToDoListItemModel(id: object.objectId ?? "N/A", title: title, description: description))
            self.tableView.reloadSections([0], with: .automatic)
            completion()
        }
    }
}

// MARK: - Account section
extension DSSListViewController {
    @objc private func logIn() {
        enum Credentials: Int { case username = 0, password = 1 }
        
        let logInAlertController = UIAlertController(title: "Log In", message: nil, preferredStyle: .alert)
        logInAlertController.addTextField { textField in
            textField.tag = Credentials.username.rawValue
            textField.placeholder = "Username"
        }
        
        logInAlertController.addTextField { textField in
            textField.tag = Credentials.password.rawValue
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        
        let logInAction = UIAlertAction(title: "Log in", style: .default) { [weak self] action in
            guard let username = logInAlertController.textFields?.first(where: { $0.tag == Credentials.username.rawValue })?.text,
                  let password = logInAlertController.textFields?.first(where: { $0.tag == Credentials.password.rawValue })?.text else {
                return logInAlertController.dismiss(animated: true, completion: nil)
            }
            
            self?.accountManager.logInWith(username: username, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    logInAlertController.dismiss(animated: true) {
                        switch result {
                        case .success(_):
                            self?.fetchItems()
                            self?.setupNavigationBar()
                        case .failure(let error):
                            self?.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            logInAlertController.dismiss(animated: true, completion: nil)
        }
        
        logInAlertController.addAction(logInAction)
        logInAlertController.addAction(cancelAction)
        
        present(logInAlertController, animated: true, completion: nil)
    }
    
    @objc private func signUp() {
        enum Credentials: Int { case username = 0, password = 1 }
        
        let logInAlertController = UIAlertController(title: "Sign Up", message: nil, preferredStyle: .alert)
        logInAlertController.addTextField { textField in
            textField.tag = Credentials.username.rawValue
            textField.placeholder = "Username"
        }
        
        logInAlertController.addTextField { textField in
            textField.tag = Credentials.password.rawValue
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        let signUpAction = UIAlertAction(title: "Sign Up", style: .default) { [weak self] action in
            guard let username = logInAlertController.textFields?.first(where: { $0.tag == Credentials.username.rawValue })?.text,
                  let password = logInAlertController.textFields?.first(where: { $0.tag == Credentials.password.rawValue })?.text else {
                return logInAlertController.dismiss(animated: true, completion: nil)
            }
                        
            self?.accountManager.signUpWith(username: username, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    logInAlertController.dismiss(animated: true) {
                        switch result {
                        case .success(_):
                            self?.fetchItems()
                            self?.setupNavigationBar()
                        case .failure(let error):
                            self?.showAlert(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            logInAlertController.dismiss(animated: true, completion: nil)
        }
        
        logInAlertController.addAction(signUpAction)
        logInAlertController.addAction(cancelAction)
        
        present(logInAlertController, animated: true, completion: nil)
    }
    
    @objc private func logOut() {
        accountManager.logOut { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            self?.models = []
            DispatchQueue.main.async {
                self?.setupNavigationBar()
                self?.tableView.reloadSections([0], with: .automatic)
            }
            self?.fetchItems()
        }
    }
}

// MARK: - UITableView delegate
extension DSSListViewController {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard !models.isEmpty else { return }
        let id = models[indexPath.row].id
        
        let object = PFObject(className: Environment.ServerClass.toDoList)
        object.objectId = id
        object.deleteInBackground { [weak self] succes, error in
            if let error = error { return print("Deletion failed with error: \(error.localizedDescription)") }
            guard succes else { return print("Failed to delete object") }
            self?.models.removeAll(where: { $0.id == id })
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { models.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DSSToDoItemCell.id, for: indexPath) as! DSSToDoItemCell
        cell.model = models[indexPath.row]
        return cell
    }
}
