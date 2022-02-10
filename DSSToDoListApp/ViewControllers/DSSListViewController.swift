//
//  DSSListViewController.swift
//  DSSToDoListApp
//
//  Created by David on 03/02/22.
//

import UIKit
import ParseSwift

extension DSSToDoListItemModel {
    init?(_ dssToDoItem: DSSToDoItem) {
        guard let id = dssToDoItem.objectId, let title = dssToDoItem.title else { return nil }
        
        self.init(id: id, title: title, description: dssToDoItem.description)
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "To do list".uppercased()
        
        setupNavigationBar()
        
        setupTableView()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewItem))
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
    enum ItemDescription: Int { case title = 0, description = 1 }
    
    private func fetchItems() {
        let query = DSSToDoItem.query()
        
        query.find { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let items):
                self.models = items.compactMap(DSSToDoListItemModel.init)
                
                DispatchQueue.main.async { self.tableView.reloadData() }
            case .failure(let error):
                #if DEBUG
                print("Failed to fetch items with error: \(error)")
                #endif
            }
        }
    }
    
    private func saveItem(title: String, description: String?) {
        let item = DSSToDoItem(title: title, description: description)
        
        item.save { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let savedItem):
                if let model = DSSToDoListItemModel(savedItem) {
                    self.models.append(model)
                    DispatchQueue.main.async {
                        self.tableView.insertRows(at: [IndexPath(row: self.models.count - 1, section: 0)], with: .bottom)
                    }
                }
            case .failure(let error):
                #if DEBUG
                print("Failed to save item with error: \(error)")
                #endif
            }
        }
    }
    
    private func updateItem(objectId id: String, title: String, description: String?) {
        var item = DSSToDoItem(objectId: id)
        item.title = title
        item.description = description
        
        item.save { [weak self] result in
            switch result {
            case .success:
                if let index = self?.models.firstIndex(where: { $0.id == id }), let model = DSSToDoListItemModel(item) {
                    self?.models[index] = model
                    DispatchQueue.main.async {
                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }
                }
            case .failure(let error):
                #if DEBUG
                print("Failed to update item with error: \(error)")
                #endif
            }
        }
    }
    
    private func deleteItem(objectId id: String) {
        let item = DSSToDoItem(objectId: id)

        item.delete { [weak self] result in
            switch result {
            case .success:
                if let row = self?.models.firstIndex(where: { $0.id == id }) {
                    DispatchQueue.main.async {
                        self?.models.remove(at: row)
                        self?.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .left)
                    }
                }
            case .failure(let error):
                #if DEBUG
                print("Failed to save item with error: \(error)")
                #endif
            }
        }
    }
    
    @objc private func handleNewItem() {
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
            guard let title = addItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.title.rawValue })?.text else {
                return addItemAlertController.dismiss(animated: true, completion: nil)
            }
            
            let description = addItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.description.rawValue })?.text
            
            addItemAlertController.dismiss(animated: true) {
                self?.saveItem(title: title, description: description)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            addItemAlertController.dismiss(animated: true, completion: nil)
        }

        addItemAlertController.addAction(addAction)
        addItemAlertController.addAction(cancelAction)

        present(addItemAlertController, animated: true, completion: nil)
    }
    
    private func handleEditItem(model: DSSToDoListItemModel) {
        let updateItemAlertController = UIAlertController(title: "Edit item", message: "Write a description for the item", preferredStyle: .alert)
        updateItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.title.rawValue
            textField.placeholder = "Title"
            textField.text = model.title
        }

        updateItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.description.rawValue
            textField.placeholder = "Description"
            textField.text = model.description
        }
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] action in
            guard let title = updateItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.title.rawValue })?.text else {
                return updateItemAlertController.dismiss(animated: true, completion: nil)
            }
            
            let description = updateItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.description.rawValue })?.text
            
            updateItemAlertController.dismiss(animated: true) {
                self?.updateItem(objectId: model.id, title: title, description: description)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            updateItemAlertController.dismiss(animated: true, completion: nil)
        }

        updateItemAlertController.addAction(updateAction)
        updateItemAlertController.addAction(cancelAction)

        present(updateItemAlertController, animated: true, completion: nil)
    }
}

// MARK: - UITableView delegate
extension DSSListViewController {
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard !models.isEmpty else { return }
        let model = models[indexPath.row]
        setupEditItem(model: model)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { models.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DSSToDoItemCell.id, for: indexPath) as! DSSToDoItemCell
        cell.model = models[indexPath.row]
        return cell
    }
    
    private func setupEditItem(model: DSSToDoListItemModel) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.handleEditItem(model: model)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteItem(objectId: model.id)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(editAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
