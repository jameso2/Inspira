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
    
    // MARK: Model data

    var quotes = [Quote]()
    var indexPathOfQuoteBeingDisplayed: IndexPath?
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // MARK: View life-cycle methods
    
    override func awakeFromNib() {
        splitViewController?.delegate = self
        navigationItem.title = "Quotes"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadQuotesFromDatabase()
        if splitViewController?.viewControllers.count == 2, let quoteDetailVC = splitViewController?.viewControllers[1].contents as? QuoteDetailViewController {
            displayInitialQuote(in: quoteDetailVC)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadQuotesFromDatabase()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }
    
    // MARK: Database management methods
    
    // Loads all quotes from the database and stores them in the quotes array.
    private func loadQuotesFromDatabase() {
        // Note: The following operation cannot be done on the background queue because managed objects
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
    
    // Adds an empty quote to the database.
    private func addQuote(to context: NSManagedObjectContext) {
        let newQuote = Quote(context: context)
        // NOTE: Storing the date/time that the quote was created allows us to sort
        // the quotes in order of most recent creation time when the quotes are
        // retrieved from the database.
        newQuote.dateCreated = Date(timeIntervalSinceNow: 0)
        try? context.save()
        quotes.insert(newQuote, at: 0)
    }
    
    // Creates a new, empty quote, inserts it into the table view, and displays the quote.
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
    
    // Removes the quote located at the given index in the quotes array from the database
    private func removeQuote(at index: Int, from context: NSManagedObjectContext) {
        context.delete(quotes[index])
        try? context.save()
        quotes.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    // Checks to see if there is an empty quote in the database. If so, the empty quote is removed
    private func findAndDeleteEmptyQuote(from context: NSManagedObjectContext) {
        let indicesOfQuotesToDelete = quotes.indices.filter { quotes[$0].isEmpty }
        // NOTE: Since this method is called each time a quote is created or each time we
        // select another quote from the table view to display, there should only ever be at
        // most one empty quote in the database
        assert(indicesOfQuotesToDelete.count <= 1)
        if indicesOfQuotesToDelete.count == 1 {
            removeQuote(at: indicesOfQuotesToDelete[0], from: context)
        }
    }
    
    // Checks to see if there is an empty quote in the database whose index in the quotes array
    // is not equal to the index argument passed. If so, the empty quote is removed
    private func findAndDeleteEmptyQuote(from context: NSManagedObjectContext, exceptAt index: inout Int) {
        let indicesOfQuotesToDelete = quotes.indices.filter { quotes[$0].isEmpty && $0 != index }
        assert(indicesOfQuotesToDelete.count <= 1)
        if indicesOfQuotesToDelete.count == 1 {
            let indexOfQuoteToDelete = indicesOfQuotesToDelete[0]
            // NOTE: If the index of the quote to be removed is less than the index argument passed, then
            // we must decrement the index argument by 1 to ensure that it refers to the same quote after
            // the other quote is removed.
            index -= (indexOfQuoteToDelete < index ? 1 : 0)
            removeQuote(at: indexOfQuoteToDelete, from: context)
        }
    }
    
    
    
    // MARK: Split view methods
    
    // If the master view  of the split view is about to be hidden and the quote being displayed in the detail view
    // is nil, a new, empty quote is created in the database to store any text input or images that the user provides.
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        if splitViewController?.viewControllers.count == 2, let quoteDetailVC = splitViewController?.viewControllers[1].contents as? QuoteDetailViewController {
            if displayMode == .primaryHidden {
                if quoteDetailVC.quoteToDisplay == nil, let context = container?.viewContext {
                    addQuote(to: context)
                    tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                    quoteDetailVC.quoteToDisplay = quotes[0]
                    indexPathOfQuoteBeingDisplayed = IndexPath(row: 0, section: 0)
                }
            }
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
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
    

    // MARK: - Table view methods

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
        if let context = container?.viewContext {
            // NOTE: We use a var to keep track of the quote index because the index of the selected quote might change after empty quotes are deleted
            var quoteIndex = indexPath.row
            findAndDeleteEmptyQuote(from: context, exceptAt: &quoteIndex)
            if splitViewController?.viewControllers.count != 2 || indexPath != indexPathOfQuoteBeingDisplayed {
                performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: quoteIndex, section: 0))
            }
            if splitViewController?.viewControllers.count == 2 {
                hideMasterView(delay: 0.8)
            }
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let context = container?.viewContext {
            removeQuote(at: indexPath.row, from: context)
            if splitViewController?.viewControllers.count == 2, let quoteDetailVC = splitViewController?.viewControllers[1].contents as? QuoteDetailViewController {
                // If we are in a split view and the quote to be deleted is the quote being displayed in the
                // detail view, we need to determine the next quote to display.
                if let displayedQuoteIndexPath = indexPathOfQuoteBeingDisplayed, indexPath == displayedQuoteIndexPath {
                    if quotes.count > 0 {
                        displayNextQuote(in: quoteDetailVC, deletedQuoteIndexPath: indexPath)
                    } else { // There are no more quotes in the table view left to display
                        quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: nil)
                        indexPathOfQuoteBeingDisplayed = nil
                    }
                }
            }
        }
    }

    // MARK: - Methods for setting the quote detail view
    
    // If we are in a split view, this method determines the initial quote to display in the detail view
    private func displayInitialQuote(in quoteDetailVC: QuoteDetailViewController) {
        let indexPathOfQuoteToDisplay = quotes.count > 0 ? IndexPath(row: 0, section: 0) : nil
        configure(quoteDetailVC, indexPathOfQuoteToDisplay: indexPathOfQuoteToDisplay)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowQuoteDetail" {
            if let quoteDetailVC = segue.destination.contents as? QuoteDetailViewController {
                if let indexPathOfQuoteToDisplay = sender as? IndexPath {
                    configure(quoteDetailVC, indexPathOfQuoteToDisplay: indexPathOfQuoteToDisplay)
                }
            }
        }
    }
    
    // Configures the quote detail view controller to display the quote at the given index path in the table view
    private func configure(_ quoteDetailVC: QuoteDetailViewController, indexPathOfQuoteToDisplay: IndexPath?) {
        quoteDetailVC.container = container
        quoteDetailVC.quoteDeletionHandler = { [weak self, unowned quoteDetailVC] in
            self?.loadQuotesFromDatabase()
            if let indexPathOfQuoteJustDeleted = self?.indexPathOfQuoteBeingDisplayed {
                self?.displayNextQuote(in: quoteDetailVC, deletedQuoteIndexPath: indexPathOfQuoteJustDeleted)
            }
        }
        indexPathOfQuoteBeingDisplayed = indexPathOfQuoteToDisplay
        if indexPathOfQuoteToDisplay != nil {
            quoteDetailVC.quoteToDisplay = quotes[indexPathOfQuoteToDisplay!.row]
        }
    }
    
    // Given the index path of a quote that has just been deleted, this method figures out what to display next
    // in the quote detail view.
    private func displayNextQuote(in quoteDetailVC: QuoteDetailViewController, deletedQuoteIndexPath: IndexPath) {
        let indexPathOfNextQuote = getIndexPathOfNextQuote(deletedQuoteIndexPath: deletedQuoteIndexPath)
        if indexPathOfNextQuote != nil {
            quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: quotes[indexPathOfNextQuote!.row])
            indexPathOfQuoteBeingDisplayed = indexPathOfNextQuote
        } else if let context = container?.viewContext {
            addQuote(to: context)
            quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: quotes[0])
            indexPathOfQuoteBeingDisplayed = IndexPath(row: 0, section: 0)
        }
    }
    
    // Given the index path of a quote that has just been deleted, this method returns the index path of the next quote
    // to display, or nil if there are no quotes left.
    private func getIndexPathOfNextQuote(deletedQuoteIndexPath: IndexPath) -> IndexPath? {
        if deletedQuoteIndexPath.row < quotes.count { // The quote that was just deleted had not been the last quote in the array, so the quote that came after it will now be displayed
            return IndexPath(row: deletedQuoteIndexPath.row, section: deletedQuoteIndexPath.section)
        } else if deletedQuoteIndexPath.row - 1 >= 0 { // The quote that was just deleted had not been the first quote in the
            // array, so the quote that came before it will now be displayed
            return IndexPath(row: deletedQuoteIndexPath.row - 1, section: deletedQuoteIndexPath.section)
        } else { // The quote that was just deleted had been the last quote in the array, so there are no other quotes to display
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
