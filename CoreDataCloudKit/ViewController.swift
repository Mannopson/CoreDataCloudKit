//
//  ViewController.swift
//  CoreDataCloudKit
//
//  Created by Abduaziz on 3/4/23.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    let reuseIdentifier = "cell-reuse-identifier"
    var tableView: UITableView! = nil
    
    private lazy var dataProvider: ValueProvider = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let provider = ValueProvider(with: appDelegate.coreDataStack.persistentContainer,
                                   fetchedResultsControllerDelegate: self)
        return provider
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        viewSetup()
    }
}

extension ViewController {
    func viewSetup() {
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
        configureHierarchy()
    }
    
    fileprivate func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
    
    @objc func addAction(sender: UIBarButtonItem) {
        let alertController = UIAlertController.init(title: "Add Value", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Write something"
        }
        alertController.addAction(UIAlertAction.init(title: "Save", style: .default, handler: { action in
            self.dataProvider.addValue(value: alertController.textFields?.last?.text, context: self.dataProvider.persistentContainer.viewContext)
        }))
        alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let item = dataProvider.fetchedResultsController.object(at: indexPath)
        var config = cell.defaultContentConfiguration()
        config.prefersSideBySideTextAndSecondaryText = false
        config.text = item.value
        config.secondaryText = item.time?.description
        cell.contentConfiguration = config
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
