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
    
    var quote = QuoteInfo() {
        didSet {
            quoteText.text = quote.text
            creator.text = quote.creator
            descriptionOfHowFound.text = quote.descriptionOfHowFound
            interpretation.text = quote.interpretation
            if let imageData = quote.imageData {
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
        if textField == quoteText {
            quote.text = quoteText.text
        } else if textField == creator {
            quote.creator = creator.text
        } else if textField == descriptionOfHowFound {
            quote.descriptionOfHowFound = descriptionOfHowFound.text
        } else {
            quote.interpretation = interpretation.text
        }
        textField.resignFirstResponder()
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let quoteToSave = quote.text, !quoteToSave.isEmpty {
            if let context = container?.viewContext {
                let newQuote = Quote(context: context)
                newQuote.text = quote.text
                newQuote.creator = quote.creator
                newQuote.descriptionOfHowFound = quote.descriptionOfHowFound
                newQuote.interpretation = quote.interpretation
            }
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
