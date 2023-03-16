//
//  ValueProvider.swift
//  CoreDataCloudKit
//
//  Created by Abduaziz on 3/15/23.
//

import Foundation
import CoreData

class ValueProvider {
    
    private(set) var persistentContainer: NSPersistentContainer
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    init(with persistentContainer: NSPersistentContainer,
         fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Entity> = {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate
        
        do {
            try controller.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("###\(#function): Failed to performFetch: \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }()
    
    func addValue(value: String?,
                  context: NSManagedObjectContext,
                  shouldSave: Bool = true,
                  completionHandler: ((_ newvalue: Entity) -> Void)? = nil) {
        
        context.perform {
            let entity = Entity.init(context: context)
            entity.value = value
            entity.time = Date.init()
            
            guard context.hasChanges else { return }
            do {
                try context.save()
                print(entity.value!, "Saved")
                completionHandler?(entity)
            } catch {
                return
            }
        }
    }
    
    func deleteValue(at indexPath: IndexPath, shouldSave: Bool = true) {
        let context = fetchedResultsController.managedObjectContext
        context.performAndWait {
            context.delete(fetchedResultsController.object(at: indexPath))
            do {
                try context.save()
            } catch {
                return
            }
        }
    }
}
