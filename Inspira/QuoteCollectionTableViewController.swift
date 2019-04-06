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
    var indexPathOfQuoteBeingDisplayed: IndexPath?
    
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
    
    private func displayInitialQuote(in quoteDetailVC: QuoteDetailViewController) {
        let indexPathOfQuoteToDisplay = quotes.count > 0 ? IndexPath(row: 0, section: 0) : nil
        configure(quoteDetailVC, indexPathOfQuoteToDisplay: indexPathOfQuoteToDisplay)
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadQuotesFromDatabase()
        if splitViewController?.viewControllers.count == 2, let quoteDetailVC = splitViewController?.viewControllers[1].contents as? QuoteDetailViewController {
            displayInitialQuote(in: quoteDetailVC)
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
        return true
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
        if let context = container?.viewContext {
            var quoteIndex = indexPath.row // the index path of the selected quote might change after empty quotes are deleted
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
                if let displayedQuoteIndexPath = indexPathOfQuoteBeingDisplayed, indexPath == displayedQuoteIndexPath {
                    if quotes.count > 0 {
                        displayNextQuote(in: quoteDetailVC, deletedQuoteIndexPath: indexPath)
                    } else {
                        quoteDetailVC.animateQuoteDeletion(nextQuoteToDisplay: nil)
                        indexPathOfQuoteBeingDisplayed = nil
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowQuoteDetail" {
            if let quoteDetailVC = segue.destination.contents as? QuoteDetailViewController {
                if let indexPathOfQuoteToDisplay = sender as? IndexPath {
                    configure(quoteDetailVC, indexPathOfQuoteToDisplay: indexPathOfQuoteToDisplay)
                }
            }
        }
    }
    
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
    
    private func getIndexPathOfNextQuote(deletedQuoteIndexPath: IndexPath) -> IndexPath? {
        if deletedQuoteIndexPath.row < quotes.count {
            return IndexPath(row: deletedQuoteIndexPath.row, section: deletedQuoteIndexPath.section)
        } else if deletedQuoteIndexPath.row - 1 >= 0 {
            return IndexPath(row: deletedQuoteIndexPath.row - 1, section: deletedQuoteIndexPath.section)
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
