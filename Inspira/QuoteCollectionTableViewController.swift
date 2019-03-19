//
//  QuoteCollectionTableViewController.swift
//  Inspira
//
//  Created by James Ortiz on 3/15/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData

struct QuoteInfo {
    var text: String?
    var creator: String?
    var descriptionOfHowFound: String?
    var interpretation: String?
    var imageData: Data?
}

class QuoteCollectionTableViewController: UITableViewController {

    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    var quotes = [QuoteInfo]()
    
    private func loadQuotesFromDatabase(_ handler: @escaping ([Quote]) -> Void) {
        container?.performBackgroundTask { context in
            do {
                let quotes = try Quote.loadAllQuotes(from: context)
                handler(quotes)
            } catch {
                print("Error: Could not load all quotes from database.")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadQuotesFromDatabase { loadedQuotes in
            DispatchQueue.main.async {
                self.quotes = loadedQuotes.map {
                    QuoteInfo(text: $0.text,
                              creator: $0.creator,
                              descriptionOfHowFound: $0.descriptionOfHowFound,
                              interpretation: $0.interpretation,
                              imageData: $0.imageData)
                    
                }
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quotes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCell", for: indexPath)
        let quote = quotes[indexPath.row]
        cell.textLabel?.text = quote.text
        cell.detailTextLabel?.text = quote.creator
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
