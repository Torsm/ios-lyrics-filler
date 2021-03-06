//
//  GameViewController.swift
//  Lyrics Filler
//
//  Created by Torben Schmitz on 26.07.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, GameDelegate {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var giveupButton: UIButton!
    @IBOutlet weak var jokerButton: UIButton!
    
    var game: Game!
    var attributedText: NSMutableAttributedString!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        textField.addTarget(self, action: #selector(textInput), for: .editingChanged)
        
        activityIndicator.startAnimating()
        textField.isEnabled = false
        timerLabel.text = ""
        giveupButton.isHidden = true
        jokerButton.isHidden = true
        
        game.delegate = self
        game.loadGame()
    }
    
    
    /**
     Gets called by the model after lyrics have been loaded and the game has been initialized.
     Decorates the textview for lyrics to hide gaps.
     */
    func gameLoaded() {
        activityIndicator.stopAnimating()
        textField.isEnabled = true
        timerLabel.text = ""
        giveupButton.isHidden = false
        jokerButton.isHidden = false
        jokerButton.setTitle("\(game.jokers) Joker", for: .normal)
        
        attributedText = NSMutableAttributedString(string: game.lyrics)
        textView.attributedText = attributedText
        for (range, _) in game.gaps.values {
            attributedText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.lightGray, range: range)
            attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGray, range: range)
            attributedText.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: textView.font!.pointSize), range: range)
        }
        textView.attributedText = attributedText
        
        textField.becomeFirstResponder()
    }
    
    
    /**
     Gets called every time the user changes the text of the input text field and passes the call to the controller if the text is not empty.
     */
    @objc func textInput(notification: NSNotification) {
        if let text = textField.text {
            game.receiveUserInput(text)
        }
    }
    
    
    /**
     Gets called by the model if the entered text is matching a gap or a joker has been used.
     Scrolls to the corresponding gap and redecorates the textview to unveil it.
     */
    func fillGap(gap: NSRange) {
        textField.text = ""
        textView.scrollRangeToVisible(gap)
        
        if game.gameOver {
            attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.init(hexString: "#E74C3C"), range: gap)
        } else {
            attributedText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.init(hexString: "#F4FFE0"), range: gap)
            attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGray, range: gap)
        }
        
        textView.attributedText = attributedText
    }
    
    
    /**
     If the game is not over yet, the user will first be prompted to confirm his action before being sent back to the main menu.
     */
    @IBAction func giveupButtonPressed(_ sender: Any) {
        if game.gameOver {
            performSegue(withIdentifier: "unwindGameView", sender: self)
        } else {
            let alert = UIAlertController(title: "Aufgeben?", message: "Möchtest du aufgeben und das Spiel beenden?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ja", style: .default) { _ in
                self.game.endGame(win: false)
            })
            alert.addAction(UIAlertAction(title: "Nein", style: .cancel))
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func jokerButtonPressed(_ sender: Any) {
        game.useJoker()
    }
    
    
    func gameOver(win: Bool) {
        view.endEditing(true)
        textField.isEnabled = false
        giveupButton.setTitle("Zurück", for: .normal)
    }
    
    
    func updateTimer(time: Int) {
        timerLabel.text = time.format()
    }
    
    
    func jokerUsed() {
        jokerButton.setTitle("\(game.jokers) Joker", for: .normal)
    }
    
    
    /**
     Will adjust the layout of the view when the keyboard will show.
     */
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            bottomConstraint.constant = CGFloat(keyboardHeight + 8)
        }
    }
    
    
    /**
     Will adjust the layout of the view when the keyboard will hide.
     */
    @objc func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = CGFloat(8)
    }
    
    
    /**
     Gets called by the model if there was an error while loading the lyrics.
     */
    func loadingFailed() {
        let alert = UIAlertController(title: "Fehler", message: "Spiel konnte nicht geladen werden.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.performSegue(withIdentifier: "unwindGameView", sender: self)
        })
        self.present(alert, animated: true, completion: nil)
    }
}


// https://stackoverflow.com/a/33397427
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


extension Int {
    /**
     Interprets the value as an amount of seconds and returns a string with the format "mm:ss"
     */
    func format() -> String {
        if self < 0 {
            return ""
        }
        
        let minutes = self / 60 % 60
        let seconds = self % 60
        return String(format:"%02i:%02i", minutes, seconds)
    }
}
