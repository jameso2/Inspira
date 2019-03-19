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

    @IBOutlet private weak var quoteText: UITextField! { didSet { quoteText.delegate = self } }
    @IBOutlet private weak var creator: UITextField! { didSet { creator.delegate = self } }
    @IBOutlet private weak var descriptionOfHowFound: UITextField! { didSet { descriptionOfHowFound.delegate = self } }
    @IBOutlet private weak var interpretation: UITextField! { didSet { interpretation.delegate = self } }
    @IBOutlet private weak var imageView: UIImageView!
    
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // TODO: Instead of happening when view will disappear, the code
        // below should execute when the edit mode is toggled off
        if let quoteToSave = quoteText.text, !quoteToSave.isEmpty {
            if let context = container?.viewContext {
                if let quoteToUpdate = quote {
                    setAttributes(for: quoteToUpdate, in: context)
                } else {
                    let newQuote = Quote(context: context)
                    setAttributes(for: newQuote, in: context)
                }
            }
        } else {
            // Show alert that quote textfield must not be empty
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
