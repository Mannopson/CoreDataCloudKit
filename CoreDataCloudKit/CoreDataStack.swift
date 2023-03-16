//
//  CoreDataStack.swift
//  CoreDataCloudKit
//
//  Created by Abduaziz on 3/11/23.
//

import Foundation
import CoreData

extension Notification.Name {
    static let didFindRelevantTransactions = Notification.Name("didFindRelevantTransactions")
}

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
    
    /**
     Track the last history token processed for a store, and write its value to file.
     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
    */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CoreDataCloudKit", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
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
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
    
    /**
     Process persistent history, posting any relevant transactions to the current view.
    */
    func processPersistentHistory() {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.performAndWait {
            
            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", "App")
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest

            let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else { return }

            // Post transactions relevant to the current view.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFindRelevantTransactions, object: self, userInfo: ["transactions": transactions])
            }

            // Deduplicate the new tags.
//            var newTagObjectIDs = [NSManagedObjectID]()
//            let tagEntityName = Entity.entity().name
//
//            for transaction in transactions where transaction.changes != nil {
//                for change in transaction.changes!
//                    where change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert {
//                        newTagObjectIDs.append(change.changedObjectID)
//                }
//            }
//            if !newTagObjectIDs.isEmpty {
//                deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
//            }
            
            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
}
