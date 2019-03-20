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
    
    var quote: Quote? {
        didSet {
            quoteText.text = quote?.text
            creator.text = quote?.creator
            descriptionOfHowFound.text = quote?.descriptionOfHowFound
            interpretation.text = quote?.interpretation
            if let imageData = quote?.imageData {
                imageView.image = UIImage(data: imageData)
                imageView.sizeToFit()
            }
        }
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
                                      handler: { action in
                                        self.presentingViewController?.dismiss(animated: true, completion: {
                                            self.deleteQuote()
                                            self.quoteDeletionHandler?()
                                        })
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
        quoteText.layer.borderWidth = 0
        quoteText.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        quoteRequirementMessage.isHidden = true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == quoteText {
            if let text = quoteText.text, text.isEmpty {
                displayQuoteRequirementMessage()
                return false
            } else {
                removeQuoteRequirementMessage()
                saveQuote()
            }
        } else if textField == creator {
            if let creator = creator.text, !creator.isEmpty {
                saveQuote()
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
    
    private func saveQuote() {
        if let context = container?.viewContext {
            if let quoteToUpdate = quote {
                setAttributes(for: quoteToUpdate, in: context)
            } else {
                let newQuote = Quote(context: context)
                setAttributes(for: newQuote, in: context)
            }
        }
    }
    
    private func deleteQuote() {
        if let context = container?.viewContext, let quoteToDelete = quote {
            context.delete(quoteToDelete)
            quote = nil
            try? context.save()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let quoteToSave = quoteText?.text, !quoteToSave.isEmpty {
            saveQuote()
        } else {
            deleteQuote()
        }
    }
}
