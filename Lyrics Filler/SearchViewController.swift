//
//  ViewController.swift
//  Lyrics Filler
//
//  Created by Torben Schmitz on 11.06.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var titleSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let game = Game()
    var results: [GeniusSong] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleSearchBar.delegate = self
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        titleSearchBar.endEditing(true)
        activityIndicator.startAnimating()
        
        guard let q = searchBar.text else {
            return
        }
        
        Genius.search(query: q) { [weak self] songs, error in
            self?.results = error == nil ? songs! : []
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.resultsTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        let result = results[indexPath.row]
        
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.artist
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt: IndexPath) {
        game.song = results[didSelectRowAt.row]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cvc = segue.destination as? ConfigurationViewController {
            cvc.game = self.game
        }
    }
    
    @IBAction func unwindToSearchViewController(segue: UIStoryboardSegue) {
        
    }
}

