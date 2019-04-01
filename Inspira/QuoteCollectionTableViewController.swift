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
        // Note: This operation cannot be done on the background queue because managed objects
        // cannot be passed between threads. If we really wanted to do this operation on the background
        // we would have to pass the object IDs between threads
        if let context = container?.viewContext {
            do {
                quotes = try Quote.loadAllQuotes(from: context)
                self.tableView.reloadData()
            } catch let error {
                print("ERROR: \(error.localizedDescription).")
            }
        }
    }
    
    private func deleteEmptyQuotes(from context: NSManagedObjectContext) -> Int {
        var emptyQuotesCounter = 0
        for quote in quotes {
            if quote.isEmpty {
                UIView.animate(withDuration: 0.2,
                               delay: 0.2 * Double(emptyQuotesCounter),
                               options: [],
                               animations: { [weak self] in
                                   context.delete(quote)
                                   if let quoteIndex = self?.quotes.firstIndex(of: quote) {
                                       self?.quotes.remove(at: quoteIndex)
                                       self?.tableView.deleteRows(at: [IndexPath(row: quoteIndex, section: 0)], with: .fade)
                                       try? context.save()
                                   }
                               }
                              )
                emptyQuotesCounter += 1
            }
        }
        return emptyQuotesCounter
    }
    
    @IBAction func createNewQuote(_ sender: UIBarButtonItem) {
        if let context = container?.viewContext {
            let numQuotesDeleted = deleteEmptyQuotes(from: context)
            UIView.animate(withDuration: 0.4,
                           delay: 0.2 * Double(numQuotesDeleted),
                           options: [],
                           animations: { [weak self] in
                               let newQuote = Quote(context: context)
                               try? context.save()
                               self?.quotes.append(newQuote)
                               self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                               self?.performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: 0, section: 0))
                           }
            )
            UIView.animate(withDuration: 0.5,
                           delay: 0.2 * Double(numQuotesDeleted) + 0.4,
                           options: [],
                           animations: { [weak self] in
                               self?.splitViewController?.preferredDisplayMode = .primaryHidden
                           }
            )
        }
    }
    
    override func viewDidAppear(_ animated: Bool) { // What's even better is using a fetched results controller
        super.viewDidAppear(animated)
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
        navigationItem.title = "Quotes"
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
        cell.textLabel?.text = (quote.text?.isEmpty ?? true) ? "Quote" : quote.text
        cell.detailTextLabel?.text = quote.creator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowQuoteDetail", sender: indexPath)
        UIView.animate(withDuration: 0.5, animations: {
            self.splitViewController?.preferredDisplayMode = .primaryHidden
        })
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
                quoteDetailVC.quoteDeletionHandler = { [unowned self, unowned quoteDetailVC] in
                    // Display the next quote (if any)
                    let indexOfNextQuote: IndexPath
                    if let indexPath = sender as? IndexPath {
                        indexOfNextQuote = IndexPath(row: indexPath.row + 1, section: 0)
                    } else {
                        indexOfNextQuote = IndexPath(row: 0, section: 0)
                    }
                    if indexOfNextQuote.row < self.quotes.count {
                        quoteDetailVC.quoteToDisplay = self.quotes[indexOfNextQuote.row]
                    } else {
                        if let splitViewVCs = quoteDetailVC.splitViewController?.viewControllers, splitViewVCs.count > 1 {
                            splitViewVCs[1].view.isHidden = true
                        } else if let navcon = quoteDetailVC.navigationController?.navigationController {
                            navcon.popViewController(animated: true)
                        }
//                            quoteDetailVC.view.isHidden = true
                    }
                }
                if let indexPath = sender as? IndexPath {
                    quoteDetailVC.quoteToDisplay = quotes[indexPath.row]
                } else {
                    quoteDetailVC.quoteToDisplay = quotes[0]
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
