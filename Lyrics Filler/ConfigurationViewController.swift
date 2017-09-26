//
//  ConfigurationViewController.swift
//  Lyrics Filler
//
//  Created by Torben Schmitz on 21.07.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//

import UIKit

class ConfigurationViewController: UIViewController {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var difficultySegments: UISegmentedControl!
    @IBOutlet weak var difficultyDescriptionLabel: UILabel!
    @IBOutlet weak var gamemodeSegments: UISegmentedControl!
    @IBOutlet weak var gamemodeDescriptionLabel: UILabel!
    
    var game: Game!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbnailImageView.downloadFrom(link: game.song!.thumbnailUrl)
        
        titleLabel.text = game.song!.title
        artistLabel.text = game.song!.artist
        
        difficultySegments.addTarget(self, action: #selector(updateDifficulty), for: .valueChanged)
        gamemodeSegments.addTarget(self, action: #selector(updateGamemode), for: .valueChanged)
        updateDifficulty()
        updateGamemode()
    }
    
    
    /**
     Updates the description label based on the selected difficulty
     */
    @objc func updateDifficulty() {
        let difficulty = Difficulty(rawValue: difficultySegments.selectedSegmentIndex)!
        difficultyDescriptionLabel.text = descriptions[difficulty]
        game.difficulty = difficulty
    }
    
    
    /**
     Updates the description label based on the selected gamemode
     */
    @objc func updateGamemode() {
        let gamemode = Gamemode(rawValue: gamemodeSegments.selectedSegmentIndex)!
        gamemodeDescriptionLabel.text = descriptions[gamemode]
        game.gamemode = gamemode
    }
    
    
    /**
     Passes the game instance to the next view's controller
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gvc = segue.destination as? GameViewController {
            gvc.game = self.game
        }
    }
}


// https://stackoverflow.com/a/27712427
extension UIImageView {
    func downloadFrom(link: String) {
        guard let url = URL(string: link) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
        }.resume()
    }
}
