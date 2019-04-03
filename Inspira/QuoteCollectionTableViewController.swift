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
    
    private func hideMasterView(delay: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] timer in
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           options: [],
                           animations: { [weak self] in
                               self?.splitViewController?.preferredDisplayMode = .primaryHidden
                           }
            )
        }
    }
    
    private func removeQuote(at index: Int, from context: NSManagedObjectContext) {
        context.delete(quotes[index])
        try? context.save()
        quotes.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    private func findAndDeleteEmptyQuote(from context: NSManagedObjectContext) {
        let indicesOfQuotesToDelete = quotes.indices.filter { quotes[$0].isEmpty }
        assert(indicesOfQuotesToDelete.count <= 1)
        if indicesOfQuotesToDelete.count == 1 {
            removeQuote(at: indicesOfQuotesToDelete[0], from: context)
        }
    }
    
    private func findAndDeleteEmptyQuote(from context: NSManagedObjectContext, exceptAt index: inout Int) {
        let indicesOfQuotesToDelete = quotes.indices.filter { quotes[$0].isEmpty && $0 != index }
        assert(indicesOfQuotesToDelete.count <= 1)
        if indicesOfQuotesToDelete.count == 1 {
            let indexOfQuoteToDelete = indicesOfQuotesToDelete[0]
            index -= (indexOfQuoteToDelete < index ? 1 : 0)
            removeQuote(at: indexOfQuoteToDelete, from: context)
        }
    }
    
    @IBAction func createNewQuote(_ sender: UIBarButtonItem) {
        if let context = container?.viewContext {
            findAndDeleteEmptyQuote(from: context)
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] timer in
                self?.addQuote(to: context)
                self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                self?.performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: 0, section: 0))
                if self?.splitViewController?.viewControllers.count == 2 {
                    self?.hideMasterView(delay: 0.8)
                }
            }
        }
    }
    
    private func addQuote(to context: NSManagedObjectContext) {
        let newQuote = Quote(context: context)
        newQuote.dateCreated = Date(timeIntervalSinceNow: 0)
        try? context.save()
        quotes.insert(newQuote, at: 0)
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
        // Delete all empty quotes except the one at index path (if it is empty)
        if let context = container?.viewContext {
            var quoteIndex = indexPath.row // the index path of the selected quote might change after empty quotes are deleted
            findAndDeleteEmptyQuote(from: context, exceptAt: &quoteIndex)
            performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: quoteIndex, section: 0))
            if splitViewController?.viewControllers.count == 2 {
                hideMasterView(delay: 0.8)
            }
        }
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
                if let indexPathOfQuoteToDisplay = sender as? IndexPath {
                    loadQuotesFromDatabase()
                    quoteDetailVC.container = container
                    quoteDetailVC.quoteDeletionHandler = { [weak self, unowned quoteDetailVC] in
                        self?.loadQuotesFromDatabase()
                        let indexPathOfNextQuote = self?.getIndexPathOfNextQuote(currentIndexPath: indexPathOfQuoteToDisplay)
                        let nextQuote: Quote?
                        if indexPathOfNextQuote != nil {
                            nextQuote = self?.quotes[indexPathOfNextQuote!.row]
                            quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: nextQuote)
                        } else if let context = self?.container?.viewContext {
                            self?.addQuote(to: context)
                            nextQuote = self?.quotes[0]
                            quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: nextQuote)
                        }
                    }
                    quoteDetailVC.quoteToDisplay = quotes[indexPathOfQuoteToDisplay.row]
                }
            }
        }
    }
    
    private func getIndexPathOfNextQuote(currentIndexPath: IndexPath) -> IndexPath? {
        if currentIndexPath.row < quotes.count {
            return IndexPath(row: currentIndexPath.row, section: currentIndexPath.section)
        } else if currentIndexPath.row - 1 >= 0 {
            return IndexPath(row: currentIndexPath.row - 1, section: currentIndexPath.section)
        } else {
            return nil
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
