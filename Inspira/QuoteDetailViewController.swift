//
//  QuoteDetailViewController.swift
//  Inspira
//
//  Created by James Ortiz on 3/15/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class QuoteDetailViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // MARK: Model
    
    var quoteToDisplay: Quote? {
        didSet {
            updateViewFromModel()
            if quoteText != nil {
                quoteText.becomeFirstResponder()
            }

        }
    }
    var quoteDeletionHandler: (() -> Void)? // Called after the quote being displayed in the detail view is removed from the database
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // MARK: Outlets
    
    @IBOutlet weak var scrollViewContent: UIView!
    @IBOutlet weak var quoteTextLabel: UILabel! {
        didSet {
            if let string = quoteTextLabel.text {
                let attributedString = NSMutableAttributedString(string: string)
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.red,
                                              range: NSRange(location: 5, length: 1))
                quoteTextLabel.attributedText = attributedString
            }
        }
    }
    @IBOutlet private weak var quoteText: UITextView! {
        didSet {
            configureTextView(quoteText)
            if quoteText.isEmpty {
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
    
    @IBOutlet private weak var imageView: UIImageView! {
        didSet {
            imageView.isUserInteractionEnabled = true
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(presentAlert(recognizer:)))
            longPress.minimumPressDuration = 1.0
            imageView.addGestureRecognizer(longPress)
        }
    }
    @IBOutlet weak var imageViewAspectRatio: NSLayoutConstraint!
    
    // The view labeled "add photo" that the user taps to set an image in the quote detail view
    @IBOutlet weak var imagePlaceholderView: UIView! {
        didSet {
            imagePlaceholderView.layer.cornerRadius = 5.0
            let tap = UITapGestureRecognizer(target: self, action: #selector(presentAlert(recognizer:)))
            imagePlaceholderView.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var imagePlaceholderViewHeight: NSLayoutConstraint! {
        didSet {
            if UIDevice().userInterfaceIdiom == .pad {
                imagePlaceholderViewHeight.constant = 425
            }
        }
    }
    
    // The message: "Please enter a quote." Displayed whenever the user has not yet set the quote and tries to modify
    // a textview other than the quote text view
    @IBOutlet weak var quoteRequirementMessage: UILabel! { didSet { quoteRequirementMessage.isHidden = true } }
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    // MARK: Methods to set image
    
    var quoteImage: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView?.image = newValue
            imagePlaceholderView?.isHidden = newValue != nil
            if let newImage = newValue, imageView != nil, imageViewAspectRatio != nil {
                imageView.removeConstraint(imageViewAspectRatio)
                let aspectRatio = NSLayoutConstraint(item: imageView!,
                                                     attribute: .width,
                                                     relatedBy: .equal,
                                                     toItem: imageView!,
                                                     attribute: .height,
                                                     multiplier: newImage.size.width / newImage.size.height,
                                                     constant: 0)
                imageView.addConstraint(aspectRatio)
                imageViewAspectRatio = aspectRatio
            }
//            saveQuote()
        }
    }
    
    // When the user taps on the image placeholder view, this method either displays an
    // action sheet to allow the user to set an image, or an error alert if neither a camera nor
    // a photo library are not available on the user's device
    @objc private func presentAlert(recognizer: UIGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) || UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            presentAlertToSetImage(recognizer: recognizer)
        } else {
            presentErrorAlert()
        }
    }
    
    // Presents an action sheet with options to: take a photo (if a camera is available on the user's device),
    // choose a photo (if a photo library is available on the user's device), and delete a photo (if a photo has
    // already been set).
    private func presentAlertToSetImage(recognizer: UIGestureRecognizer) {
        let gestureLocation = recognizer.location(in: imagePlaceholderView)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo",
                                          style: .default,
                                          handler: { [weak self] action in
                                              self?.quoteImageBeingSet = true
                                              self?.presentImagePicker(for: .camera)
                                          }
            ))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Choose Photo",
                                          style: .default,
                                          handler: { [weak self] action in
                                              self?.quoteImageBeingSet = true
                                              self?.presentImagePicker(for: .photoLibrary, gestureLocation: gestureLocation)
                                          }
            ))
        }
        if recognizer.view == imageView {
            alert.addAction(UIAlertAction(title: "Delete Photo",
                                          style: .default,
                                          handler: { [weak self] action in
                                              self?.quoteImage = nil
                                              self?.saveQuote()
                                          }
            ))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.modalPresentationStyle = .popover
        let ppc = alert.popoverPresentationController
        ppc?.sourceView = imagePlaceholderView
        ppc?.sourceRect = CGRect(origin: gestureLocation, size: CGSize.zero)
        present(alert, animated: true, completion: nil)
    }
    
    private var quoteImageBeingSet = false
    
    // Presents an alert to notify user that neither a camera nor a photo library is available on the
    // user's device
    private func presentErrorAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = "Camera and Photo Library Unavailable"
        alert.message = "Your device does not have a camera or photo library for setting the image."
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Presents the image picker MVC for the given source type (either camera or photo library)
    private func presentImagePicker(for sourceType: UIImagePickerController.SourceType, gestureLocation: CGPoint? = nil) {
        let picker = UIImagePickerController()
        let mediaTypeImage = kUTTypeImage as String
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = [mediaTypeImage]
        if sourceType == .photoLibrary {
            picker.modalPresentationStyle = .popover
            let ppc = picker.popoverPresentationController
            ppc?.sourceView = imagePlaceholderView
            if let sourceRectOrigin = gestureLocation {
                ppc?.sourceRect = CGRect(origin: sourceRectOrigin, size: CGSize.zero)
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Extract image from info and set imageView
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            quoteImage = image
            saveQuote()
        }
        picker.presentingViewController?.dismiss(animated: true)
        quoteImageBeingSet = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
        quoteImageBeingSet = false
    }
    
    // MARK: TextView methods
    
    private func configureTextView(_ textView: UITextView) {
        textView.delegate = self
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 0.35
        textView.layer.cornerRadius = 6.0
    }
    
    // Displays the quote requirement message whenever the user tries to begin
    // editing another textfield and has not yet entered a quote; however, unlike
    // textFieldShouldEndEditing, this method is not called (and thus the quote
    // requirement message is not displayed) when the view is about
    // to disappear (e.g. when we click to go back to our collection of quotes)
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView != quoteText, quoteText.isEmpty {
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
    
    // Prohibits user from entering leading white spaces or newlines in textview while still allowing user
    // to delete text.
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location == 0, !text.isEmpty, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }
    
    // Resizes the given textview so that all of its text fits. If the height of the textview reaches a certain value
    // (given by Constants.maxTextViewHeight) then scrolling is enabled in the textview.
    private func resize(_ textView: UITextView) {
        let sizeThatFits = textView.sizeThatFits(CGSize(width: textView.frame.width, height: Constants.maxTextViewHeight))
        let newHeight = min(sizeThatFits.height, Constants.maxTextViewHeight)
        textView.isScrollEnabled = newHeight == Constants.maxTextViewHeight
        switch textView {
        case quoteText: quoteTextHeight.constant = newHeight
        case creator: creatorHeight.constant = newHeight
        case descriptionOfHowFound: descriptionOfHowFoundHeight.constant = newHeight
        case interpretation: interpretationHeight.constant = newHeight
        default: break
        }
    }
    
    // Removes the quote requirement message as soon as the user types a non-white space character into the quote textfield.
    // If the textview being modified is the quote textview or creator textview, the quote is saved.
    func textViewDidChange(_ textView: UITextView) {
        resize(textView)
        if textView == quoteText || textView == creator {
            saveQuote()
            if !quoteText.isEmpty {
                removeQuoteRequirementMessage()
            }
        }
    }
    
    // The boolean below is set to true as soon as the user chooses the "Delete Quote" option from the action
    // sheet for deleting quotes. This prevents the quote from being saved when textViewDidEndEditing is called
    // after the user chooses to delete the quote
    private var quoteIsMarkedForDeletion = false
    
    // Trims the trailing white spaces and newlines from the textviews and saves the quote after the quoteText or creator
    // text views are done being edited
    func textViewDidEndEditing(_ textView: UITextView) {
        trimText(in: textView)
        if textView == quoteText || textView == creator {
            if !textView.isEmpty, !quoteIsMarkedForDeletion {
                saveQuote()
            }
        }
    }
    
    private func trimText(in textView: UITextView) {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        textView.text = trimmedText
        resize(textView)
    }
    
    // Sets the text of the given textview to the text passed as an argument
    private func set(textView: UITextView?, to text: String?) {
        textView?.text = text
        if textView != nil {
            resize(textView!)
        }
    }
    
    // MARK: Loading the quote to the view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewFromModel()
    }
    
    private func updateViewFromModel() {
        set(textView: quoteText, to: quoteToDisplay?.text)
        set(textView: creator, to: quoteToDisplay?.creator)
        set(textView: descriptionOfHowFound, to: quoteToDisplay?.descriptionOfHowFound)
        set(textView: interpretation, to: quoteToDisplay?.interpretation)
        if let imageData = quoteToDisplay?.imageData {
            quoteImage = UIImage(data: imageData)
        } else if !quoteIsMarkedForDeletion { // This boolean check allows the quoteImage to still be displayed as the deletion animation occurs
            quoteImage = nil
        }
        deleteButton?.isEnabled = quoteToDisplay != nil
    }
    
    // MARK: Methods to save/delete quote
    
    private func saveQuote() {
        if let context = container?.viewContext {
            if let quoteToUpdate = quoteToDisplay { // Updates the existing quote in the database
                setAttributes(for: quoteToUpdate, in: context)
            } else if allOutletsSet { // Creates a new quote in the database
                let newQuote = Quote(context: context)
                setAttributes(for: newQuote, in: context)
                quoteToDisplay = newQuote
            }
        }
    }
    
    // Sets the attribes of the quote database entry
    private func setAttributes(for quote: Quote, in context: NSManagedObjectContext) {
        quote.text = quoteText.text.trimmingCharacters(in: .whitespacesAndNewlines)
        quote.creator = creator.text.trimmingCharacters(in: .whitespacesAndNewlines)
        quote.descriptionOfHowFound = descriptionOfHowFound.text
        quote.interpretation = interpretation.text
        quote.imageData = imageView.image?.jpegData(compressionQuality: 1.0)
        try? context.save()
    }
    
    // Checks if all of the textviews and the imageView outlet is set
    private var allOutletsSet: Bool {
        if quoteText != nil, creator != nil, descriptionOfHowFound != nil, interpretation != nil, imageView != nil {
            return true
        }
        return false
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
    
    private func deleteQuote() {
        // NOTE: Setting the boolean below to true is necessary in the case that the user clicks on
        // "Delete" before the quote has even been saved. In that case, quoteToDisplay
        // would be nil, textViewDidEndEditing would be called, and the quote would be
        // saved even though it had been deleted.
        quoteIsMarkedForDeletion = true
        if let context = container?.viewContext, let quoteToDelete = quoteToDisplay {
            context.delete(quoteToDelete)
            quoteToDisplay = nil
            try? context.save()
        }
    }
    
    func animateQuoteDeletion(nextQuoteToDisplay: Quote?) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3,
                                                       delay: 0,
                                                       options: [.curveEaseInOut],
                                                       animations: { [weak self] in
                                                           self?.scrollViewContent.alpha = 0
                                                       },
                                                       completion: { [weak self] completed in
                                                           self?.quoteIsMarkedForDeletion = false
                                                           self?.quoteToDisplay = nextQuoteToDisplay
                                                           self?.scrollViewContent.alpha = 1
                                                       }
        )
    }
    
    // If the view is about to disappear (e.g. when the user clicks to go back to the table view of quotes), the quote
    // is saved if any of the textviews is non-empty or if the image is set to a non-nil value; otherwise, the quote
    // is deleted
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if allOutletsSet, !quoteIsMarkedForDeletion, !quoteImageBeingSet {
            if quoteText.isEmpty, creator.isEmpty, descriptionOfHowFound.isEmpty, interpretation.isEmpty, quoteImage == nil {
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

extension UITextView {
    var isEmpty: Bool {
        return self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
