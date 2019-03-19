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
            let quotes = try context.fetch(request)
            return quotes
        } catch {
            throw error
        }
    }
    
    class func addQuote(_ quoteInfo: QuoteInfo, to context: NSManagedObjectContext) {
        let quote = Quote(context: context)
        quote.text =
        quote.creator =
        quote.descriptionOfHowFound =
        quote.id =
        quote.image =
        quote.interpretation =
        try? context.save()
    }
}
