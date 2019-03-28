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
        do {
            return try context.fetch(request).reversed()
        } catch {
            throw error
        }
    }
}
