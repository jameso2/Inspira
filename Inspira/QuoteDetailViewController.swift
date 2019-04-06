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
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var quoteDeletionHandler: (() -> Void)?
    
    // MARK: Outlets
    
    @IBOutlet weak var scrollViewContent: UIView!
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
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(presentAlert(recognizer:)))
            longPress.minimumPressDuration = 3.0
            imageView.addGestureRecognizer(longPress)
        }
    }
    @IBOutlet weak var imageViewAspectRatio: NSLayoutConstraint!
    
    @IBOutlet weak var imagePlaceholderView: UIView! {
        didSet {
            configureImagePlaceholderView()
        }
    }
    
    @IBOutlet weak var imagePlaceholderViewHeight: NSLayoutConstraint! {
        didSet {
            if UIDevice().userInterfaceIdiom == .pad {
                imagePlaceholderViewHeight.constant = 425
            }
        }
    }
    
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
        }
    }
    
    
    @IBOutlet weak var quoteRequirementMessage: UILabel! { didSet { quoteRequirementMessage.isHidden = true } }
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    // MARK: Image view functionality
    
    private func configureImagePlaceholderView() {
        imagePlaceholderView.layer.cornerRadius = 5.0
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentAlert(recognizer:)))
        imagePlaceholderView.addGestureRecognizer(tap)
    }
    
    @objc private func presentAlert(recognizer: UIGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) || UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            presentAlertToSetImage(recognizer: recognizer)
        } else {
            presentErrorAlert()
        }
    }
    
    private func presentAlertToSetImage(recognizer: UIGestureRecognizer) {
        let gestureLocation = recognizer.location(in: imagePlaceholderView)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo",
                                          style: .default,
                                          handler: { [weak self] action in
                                              self?.setImage(from: .camera)
                                          }
            ))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Choose Photo",
                                          style: .default,
                                          handler: { [weak self] action in
                                              self?.setImage(from: .photoLibrary, gestureLocation: gestureLocation)
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
    
    private func presentErrorAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.title = "Camera and Photo Library Unavailable"
        alert.message = "Your device does not have a camera or photo library for setting the image."
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func setImage(from sourceType: UIImagePickerController.SourceType, gestureLocation: CGPoint? = nil) {
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
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
    
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
        if textView == quoteText || textView == creator {
            saveQuote()
            if !quoteText.isEmpty {
                removeQuoteRequirementMessage()
            }
        }
    }
    
    private var quoteIsMarkedForDeletion = false
    
    // NOTE: The delegate method below is helpful primarily because it allows us to trim the text of trailing white
    // spaces and newlines and save the quotes after the quoteText or creator text views are done being edited
    
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
    
    private func updateViewFromModel() {
        quoteText?.text = quoteToDisplay?.text
        creator?.text = quoteToDisplay?.creator
        descriptionOfHowFound?.text = quoteToDisplay?.descriptionOfHowFound
        interpretation?.text = quoteToDisplay?.interpretation
        if let imageData = quoteToDisplay?.imageData {
            quoteImage = UIImage(data: imageData)
        } else if !quoteIsMarkedForDeletion { // The deletion animation looks better if the quoteImage is still displayed as the animation occurs
            quoteImage = nil
        }
        deleteButton?.isEnabled = quoteToDisplay != nil
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
        quote.text = quoteText.text.trimmingCharacters(in: .whitespacesAndNewlines)
        quote.creator = creator.text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        print("Quote being saved")
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
        // NOTE: The boolean below is necessary in the case that the user clicks on
        // "Delete" before the quote has even been saved. In that case, quoteToDisplay
        // would be nil, textViewDidEndEditing would be called, and the quote would be
        // saved even though it had been deleted.
        print("Quote being deleted")
        quoteIsMarkedForDeletion = true
        if let context = container?.viewContext, let quoteToDelete = quoteToDisplay {
            context.delete(quoteToDelete)
            quoteToDisplay = nil
            try? context.save()
        }
    }
    
    func animateQuoteDeletion(nextQuoteToDisplay: Quote?) {
        if let deleteButtonView = deleteButton.value(forKey: "view") as? UIView {
            let scrollViewContentOriginalFrame = scrollViewContent.frame
            let newOrigin = deleteButtonView.superview!.convert(deleteButtonView.frame.origin, to: scrollViewContent.superview)
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6,
                                                           delay: 0,
                                                           options: [.curveEaseInOut],
                                                           animations: { [weak self] in
                                                               self?.scrollViewContent.frame = CGRect(origin: newOrigin, size: CGSize.zero)
                                                               self?.scrollViewContent.alpha = 0
                                                           },
                                                           completion: { [weak self] completed in
                                                               self?.quoteIsMarkedForDeletion = false
                                                               self?.quoteToDisplay = nextQuoteToDisplay
                                                               self?.scrollViewContent.frame = scrollViewContentOriginalFrame
                                                               self?.scrollViewContent.alpha = 1
                                                           }
            )
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if allOutletsSet, !quoteIsMarkedForDeletion {
            if quoteText.isEmpty, creator.isEmpty, descriptionOfHowFound.isEmpty, interpretation.isEmpty, quoteImage == nil {
                print("This is where delete quote is called")
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
