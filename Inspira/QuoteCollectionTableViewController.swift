//
//  QuoteCollectionTableViewController.swift
//  Inspira
//
//  Created by James Ortiz on 3/15/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData

class QuoteCollectionTableViewController: UITableViewController, UISplitViewControllerDelegate {

    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    var quotes = [Quote]()
    
    private func loadQuotesFromDatabase() {
        container?.performBackgroundTask { context in
            do {
                let quotes = try Quote.loadAllQuotes(from: context)
                DispatchQueue.main.async {
                    self.quotes = quotes
                    self.tableView.reloadData()
                }
            } catch {
                print("Error: Could not load all quotes from database.")
            }
        }
    }
    
    @IBAction func createNewQuote(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowQuoteDetail", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadQuotesFromDatabase()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }
    
    override func awakeFromNib() {
        splitViewController?.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let quoteDetailVC = secondaryViewController.contents as? QuoteDetailViewController {
            if quoteDetailVC.quoteDeletionHandler == nil {
                return true
            }
        }
        return false
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowQuoteDetail", sender: indexPath)
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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowQuoteDetail" {
            if let quoteDetailVC = segue.destination.contents as? QuoteDetailViewController {
                quoteDetailVC.container = container
                quoteDetailVC.quoteDeletionHandler = { [weak self, unowned quoteDetailVC] in
                    // Display the next quote (if any)
                    if let quoteCount = self?.quotes.count {
                        let indexOfNextQuote: IndexPath
                        if let indexPath = sender as? IndexPath {
                            indexOfNextQuote = IndexPath(row: indexPath.row + 1, section: 0)
                        } else {
                            indexOfNextQuote = IndexPath(row: 0, section: 0)
                        }
                        if indexOfNextQuote.row < quoteCount {
                            quoteDetailVC.quote = self?.quotes[indexOfNextQuote.row]
                        } else {
                            quoteDetailVC.view.isHidden = true
                        }
                    }
                }
                if let indexPath = sender as? IndexPath {
                    quoteDetailVC.quote = quotes[indexPath.row]
                }
            }
        }
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}
