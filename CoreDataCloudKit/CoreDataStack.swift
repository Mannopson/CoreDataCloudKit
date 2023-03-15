//
//  CoreDataStack.swift
//  CoreDataCloudKit
//
//  Created by Abduaziz on 3/11/23.
//

import Foundation
import CoreData

class CoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Create a container that can load CloudKit-backed stores
        let container = NSPersistentCloudKitContainer(name: "Model")
        
        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (_, error) in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent stores:\(error)")
        })
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = "App"
        
        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }
        
        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: container)
        
        return container
    }()
}

extension CoreDataStack {
    /**
     Handle remote store change notifications (.NSPersistentStoreRemoteChange).
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        print("###\(#function): Merging changes from the other persistent store coordinator.")
        
        // Process persistent history to merge changes from other coordinators.
//        historyQueue.addOperation {
//            self.processPersistentHistory()
//        }
    }
}
