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
    
    private func deleteEmptyQuotes(from context: NSManagedObjectContext, exceptAt index: Int? = nil, shouldAddNewQuote: Bool = false) -> Int {
        var counter = 1
        let indicesOfQuotesToDelete = quotes.indices.filter {
            if let indexOfQuoteNotToDelete = index {
                return quotes[$0].isEmpty && indexOfQuoteNotToDelete != $0
            }
            return quotes[$0].isEmpty
        }
        for indexToDelete in indicesOfQuotesToDelete.sorted(by: >) {
            let quote = quotes[indexToDelete]
            Timer.scheduledTimer(withTimeInterval: 0.3 * Double(counter), repeats: false) { [weak self] timer in
                context.delete(quote)
                try? context.save()
                self?.quotes.remove(at: indexToDelete)
                self?.tableView.deleteRows(at: [IndexPath(row: indexToDelete, section: 0)], with: .fade)
            }
            counter += 1
            if index != nil, index! > indexToDelete {
                index! -= 1
            }
        }
        return counter
    }
    
    @IBAction func createNewQuote(_ sender: UIBarButtonItem) {
        if let context = container?.viewContext {
            let emptyQuotesCounter = deleteEmptyQuotes(from: context, shouldAddNewQuote: true)
            Timer.scheduledTimer(withTimeInterval: 0.3 * Double(emptyQuotesCounter), repeats: false) { [weak self] timer in
                self?.addQuote(to: context)
                self?.performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: 0, section: 0))
                self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            }
            if splitViewController?.viewControllers.count == 2 {
                hideMasterView(delay: 0.3 * Double(emptyQuotesCounter) + 0.7)
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
            var quoteIndex: Int! = indexPath.row // the index path of the selected quote might change after empty quotes are deleted
            let numQuotesDeleted = deleteEmptyQuotes(from: context, exceptAt: quoteIndex)
            performSegue(withIdentifier: "ShowQuoteDetail", sender: IndexPath(row: quoteIndex, section: 0))
            if splitViewController?.viewControllers.count == 2 {
                hideMasterView(delay: 0.3 * Double(numQuotesDeleted))
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
                    quoteDetailVC.container = container
                    quoteDetailVC.quoteDeletionHandler = { [weak self, unowned quoteDetailVC] in
                        self?.loadQuotesFromDatabase()
                        let indexPathOfNextQuote = self?.getIndexPathOfNextQuote(currentIndexPath: indexPathOfQuoteToDisplay)
                        let nextQuote: Quote?
                        if indexPathOfNextQuote != nil {
                            nextQuote = self?.quotes[indexPathOfNextQuote!.row]
                            self?.animateQuoteDeletion(with: quoteDetailVC, nextQuoteToDisplay: nextQuote)
                        } else if let context = self?.container?.viewContext {
                            self?.addQuote(to: context)
                            nextQuote = self?.quotes[0]
                            self?.animateQuoteDeletion(with: quoteDetailVC, nextQuoteToDisplay: nextQuote)
                        }
                        
//                        let indexOfNextQuote: IndexPath
//                        if let indexPath = sender as? IndexPath {
//                            indexOfNextQuote = IndexPath(row: indexPath.row + 1, section: 0)
//                        } else {
//                            indexOfNextQuote = IndexPath(row: 0, section: 0)
//                        }
//                        if indexOfNextQuote.row < self.quotes.count {
//                            UIView.transition(with: quoteDetailVC.view,
//                                              duration: 0.6,
//                                              options: .transitionFlipFromTop,
//                                              animations: {
//                                                  quoteDetailVC.quoteToDisplay = self.quotes[indexOfNextQuote.row]
//                                              })
//    //                        quoteDetailVC.quoteToDisplay = self.quotes[indexOfNextQuote.row]
//                        } else {
//                            if let splitViewVCs = quoteDetailVC.splitViewController?.viewControllers, splitViewVCs.count > 1 {
//                                splitViewVCs[1].view.isHidden = true
//                            } else if let navcon = quoteDetailVC.navigationController?.navigationController {
//                                navcon.popViewController(animated: true)
//                            }
//    //                            quoteDetailVC.view.isHidden = true
//                        }
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
    
    private func animateQuoteDeletion(with quoteDetailViewController: QuoteDetailViewController, nextQuoteToDisplay: Quote?) {
        if let deleteButtonView = quoteDetailViewController.deleteButton.value(forKey: "view") as? UIView {
            let quoteDetailViewOriginalFrame = quoteDetailViewController.scrollViewContent.frame
            let newOrigin = deleteButtonView.convert(deleteButtonView.frame.origin, to: quoteDetailViewController.scrollViewContent.superview)
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6,
                                                           delay: 0,
                                                           options: [.curveEaseInOut],
                                                           animations: {
                                                               quoteDetailViewController.scrollViewContent.frame = CGRect(origin: newOrigin, size: CGSize.zero)
                                                               quoteDetailViewController.scrollViewContent.alpha = 0
                                                           },
                                                           completion: { completed in
                                                               quoteDetailViewController.quoteToDisplay = nextQuoteToDisplay
                                                               quoteDetailViewController.scrollViewContent.frame = quoteDetailViewOriginalFrame
                                                               quoteDetailViewController.scrollViewContent.alpha = 1
                                                           }
            )
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
