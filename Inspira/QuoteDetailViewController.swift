//
//  QuoteDetailViewController.swift
//  Inspira
//
//  Created by James Ortiz on 3/15/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData

class QuoteDetailViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    // MARK: Model
    
    var quoteToDisplay: Quote? {
        didSet {
            updateViewFromModel()
        }
    }
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var quoteDeletionHandler: (() -> Void)?
    
    // MARK: Outlets
    
    @IBOutlet private weak var quoteText: UITextView! {
        didSet {
            configureTextView(quoteText)
            if let text = quoteText.text, text.isEmpty {
                quoteText.becomeFirstResponder()
            }
        }
    }
    @IBOutlet private weak var quoteTextHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var creator: UITextView! { didSet { configureTextView(creator) } }
    @IBOutlet private weak var creatorHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var descriptionOfHowFound: UITextView! { didSet { configureTextView(descriptionOfHowFound) } }
    @IBOutlet private weak var descriptionOfHowFoundHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var interpretation: UITextView! { didSet { configureTextView(interpretation) } }
    @IBOutlet private weak var interpretationHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet weak var quoteRequirementMessage: UILabel! { didSet { quoteRequirementMessage.isHidden = true } }
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    // MARK: TextView functionality
    
    private func configureTextView(_ textView: UITextView) {
        textView.delegate = self
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 0.35
        textView.layer.cornerRadius = 6.0
    }
    
    // Note: Like textFieldShouldEndEditing, the delegate method below allows us
    // to display the quote requirement message whenever the user tries to begin
    // editing another textfield and has not yet entered a quote; however, unlike
    // textFieldShouldEndEditing, this method is not called (and the quote
    // requirement message is not displayed) when the view is about
    // to disappear (e.g. when we click to go back to our collection of quotes)
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView != quoteText, let text = quoteText.text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayQuoteRequirementMessage()
            return false
        }
        return true
    }
    
    private func displayQuoteRequirementMessage() {
        quoteText.layer.borderWidth = 5.0
        quoteText.layer.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1).cgColor
        quoteRequirementMessage.isHidden = false
    }
    
    private func removeQuoteRequirementMessage() {
        configureTextView(quoteText)
        quoteRequirementMessage?.isHidden = true
    }
    
    // The delegate method below allows us to prevent the user from entering leading white spaces or newlines
    // while still allowing the user to delete the first character.
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location == 0, !text.isEmpty, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }
    
    private func resize(_ textView: UITextView) {
        let sizeThatFits = textView.sizeThatFits(CGSize(width: textView.frame.width, height: Constants.maxTextViewHeight))
        let newHeight = min(sizeThatFits.height, Constants.maxTextViewHeight)
        switch textView {
        case quoteText: quoteTextHeight.constant = newHeight
        case creator: creatorHeight.constant = newHeight
        case descriptionOfHowFound: descriptionOfHowFoundHeight.constant = newHeight
        case interpretation: interpretationHeight.constant = newHeight
        default: break
        }
    }
    
    // The delegate method below allows us to remove the quote requirement message as soon as
    // the user types a character into the quote textfield. This method is called even when a
    // user deletes characters.
    
    func textViewDidChange(_ textView: UITextView) {
        resize(textView)
        if textView == quoteText {
            let text = quoteText.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                removeQuoteRequirementMessage()
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        trimText(in: textView)
        if textView == quoteText, !quoteText.text.isEmpty {
            print("Quote is going to be saved")
            saveQuote()
        } else if textView == creator, !creator.text.isEmpty {
            saveQuote()
        }
    }
    
    private func trimText(in textView: UITextView) {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        textView.text = trimmedText
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
        super.viewDidLoad()
        updateViewFromModel()
        resize(quoteText)
        resize(creator)
        resize(descriptionOfHowFound)
        resize(interpretation)
    }
    
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
    
    private struct Constants {
        static let maxTextViewHeight: CGFloat = 125
    }
}
