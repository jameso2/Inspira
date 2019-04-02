//
//  Quote.swift
//  Inspira
//
//  Created by James Ortiz on 3/19/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData

class Quote: NSManagedObject {
    class func loadAllQuotes(from context: NSManagedObjectContext) throws -> [Quote] {
        let request: NSFetchRequest<Quote> = Quote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            throw error
        }
    }
    
    var isEmpty: Bool {
        if self.text.isEmpty, self.creator.isEmpty, self.descriptionOfHowFound.isEmpty, self.interpretation.isEmpty {
            return true
        }
        return false
    }
}

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        return self?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
}
