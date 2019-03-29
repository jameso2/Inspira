//
//  QuoteDetailViewController.swift
//  Inspira
//
//  Created by James Ortiz on 3/15/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData

class QuoteDetailViewController: UIViewController, UITextFieldDelegate {
    
    var quoteToDisplay: Quote? {
        didSet {
            updateViewFromModel()
        }
    }
    
    private func updateViewFromModel() {
        quoteText?.text = quoteToDisplay?.text
        creator?.text = quoteToDisplay?.creator
        descriptionOfHowFound?.text = quoteToDisplay?.descriptionOfHowFound
        interpretation?.text = quoteToDisplay?.interpretation
        if let imageData = quoteToDisplay?.imageData {
            imageView?.image = UIImage(data: imageData)
            imageView?.sizeToFit()
        }
    }
    
    override func viewDidLoad() {
        updateViewFromModel()
    }
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var quoteDeletionHandler: (() -> Void)?

    @IBOutlet private weak var quoteText: UITextField! {
        didSet {
            quoteText.delegate = self
            if let text = quoteText.text, text.isEmpty {
                quoteText.becomeFirstResponder()
            }
        }
    }
    @IBOutlet private weak var creator: UITextField! { didSet { creator.delegate = self } }
    @IBOutlet private weak var descriptionOfHowFound: UITextField! { didSet { descriptionOfHowFound.delegate = self } }
    @IBOutlet private weak var interpretation: UITextField! { didSet { interpretation.delegate = self } }
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet weak var quoteRequirementMessage: UILabel! {
        didSet {
            quoteRequirementMessage.isHidden = true
        }
    }
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBAction func presentDeleteAlert(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete Quote",
                                      style: .destructive,
                                      handler: { [weak self] action in
                                            self?.deleteQuote()
                                            self?.quoteDeletionHandler?()
                                      }
        ))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.modalPresentationStyle = .popover
        let ppc = alert.popoverPresentationController
        ppc?.barButtonItem = deleteButton
        present(alert, animated: true, completion: nil)
    }
    
    private func displayQuoteRequirementMessage() {
        quoteText.layer.borderWidth = 5.0
        quoteText.layer.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1).cgColor
        quoteRequirementMessage.isHidden = false
    }
    
    private func removeQuoteRequirementMessage() {
        quoteText?.layer.borderWidth = 0
        quoteText?.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        quoteRequirementMessage?.isHidden = true
    }
    
    // Note: Like textFieldShouldEndEditing, the delegate method below allows us
    // to display the quote requirement message whenever the user tries to begin
    // editing another textfield and has not yet entered a quote; however, unlike
    // textFieldShouldEndEditing, this method is not called (and the quote
    // requirement message is not displayed) when the view is about
    // to disappear (e.g. when we click to go back to our collection of quotes)
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField != quoteText, let text = quoteText.text, text.isEmpty {
            displayQuoteRequirementMessage()
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == quoteText, let text = quoteText.text, !text.isEmpty {
            saveQuote()
        } else if textField == creator, let creator = creator.text, !creator.isEmpty {
            saveQuote()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // The delegate method below allows us to remove the quote requirement message as soon as
    // the user types a character into the quote textfield. This method is called even when a
    // user deletes characters.
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quoteText {
            removeQuoteRequirementMessage()
        }
        return true
    }
    
    private func setAttributes(for quote: Quote, in context: NSManagedObjectContext) {
        quote.text = quoteText.text
        quote.creator = creator.text
        quote.descriptionOfHowFound = descriptionOfHowFound.text
        quote.interpretation = interpretation.text
        quote.imageData = imageView.image?.jpegData(compressionQuality: 1.0)
        try? context.save()
    }
    
    private var allOutletsSet: Bool {
        if quoteText != nil, creator != nil, descriptionOfHowFound != nil, interpretation != nil, imageView != nil {
            return true
        }
        return false
    }
    
    private func saveQuote() {
        if let context = container?.viewContext {
            if let quoteToUpdate = quoteToDisplay {
                setAttributes(for: quoteToUpdate, in: context)
            } else if allOutletsSet {
                let newQuote = Quote(context: context)
                setAttributes(for: newQuote, in: context)
                quoteToDisplay = newQuote
            }
        }
    }
    
    private func deleteQuote() {
        if let context = container?.viewContext, let quoteToDelete = quoteToDisplay {
            context.delete(quoteToDelete)
            quoteToDisplay = nil
            try? context.save()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if quoteToDisplay != nil, let text = quoteText?.text {
            if text.isEmpty {
                deleteQuote()
            } else {
                saveQuote()
            }
        }
    }
}
