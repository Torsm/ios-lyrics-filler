//
//  Game.swift
//  Lyrics Filler
//
//  Created by Torben Schmitz on 29.06.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//

import UIKit

public class Game {
    var song: GeniusSong!
    var difficulty: Difficulty!
    var gamemode: Gamemode!
    var delegate: GameDelegate!
    var lyrics: String!
    var gaps: [String:(NSRange, Bool)] = [:]
    var gameOver: Bool = true
    var timer: Timer!
    var startTime: Date?
    var jokers: Int = 0
    
    
    /**
     Gets called by the Controller to initialize the game and load the lyrics of the selected song.
     */
    func loadGame() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        
        Genius.getLyrics(song: song!) { lyrics, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    self.delegate?.loadingFailed()
                }
                return
            }
            
            self.lyrics = lyrics!
            self.generateGaps()
            self.gameOver = false
            self.startTime = Date()
            self.jokers = self.difficulty.amountOfJokers()
            
            DispatchQueue.main.async {
                self.delegate.gameLoaded()
            }
        }
    }
    
    
    /**
     Gets fired every second by a scheduled timer.
     If time is relevant to the selected gamemode, the timer of the view gets updated, and optionally the game is over if a period based on the difficulty has passed since start of the game.
     */
    @objc private func timerTick() {
        guard gamemode != .free, let diff = startTime?.timeIntervalSinceNow else {
            return
        }
        
        if gamemode == .sprint {
            delegate.updateTimer(time: Int(diff) * -1)
        } else {
            let time = gaps.count * difficulty.availableTimePerGap() + Int(diff)
            delegate.updateTimer(time: time)
            if time <= 0 {
                endGame(win: false)
            }
        }
    }
    
    
    /**
     Gaps will be reset and a loop will iterate over each distinct word in the loaded lyrics.
     A word has to have at least 4 characters, be alphanumeric, not already in the set of gaps, and has to pass a random chance based on difficulty.
     The word is stored lowercase for ease of comparison, and is associated with the range in the whole string, as well as a flag indicating if the gap has been filled or not.
     */
    private func generateGaps() {
        gaps = [:]
        let lyrics = NSString(string: self.lyrics)
        for word in lyrics.components(separatedBy: .whitespacesAndNewlines) {
            guard word.lengthOfBytes(using: .utf8) >= 4,
                word.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil,
                !gaps.keys.contains(word.lowercased()),
                difficulty.pollRandom()
                else {
                continue
            }
            
            gaps[word.lowercased()] = (lyrics.range(of: "(?<!\\S)\(word)(?!\\S)", options: .regularExpression), false)
        }
    }
    
    
    func endGame(win: Bool) {
        timer.invalidate()
        startTime = nil
        gameOver = true
        delegate.gameOver(win: win)
        
        for (_, (range, filled)) in gaps {
            if !filled {
                delegate.fillGap(gap: range)
            }
        }
    }
    
    
    /**
     Gets called by the controller every time the user changes the text of the input textfield.
     The gaps will be searched for a key-value set matching the entered text that has not been filled yet.
     If a gap is found, it will be filled.
     */
    func receiveUserInput(_ text: String) {
        for (word, (range, filled)) in gaps {
            if !filled, text.caseInsensitiveCompare(word) == .orderedSame {
                fillGap(word: word, range: range)
            }
        }
    }
    
    
    /**
     Gets called by the controller when a user wishes to use a joker.
     If there are jokers left to use and the game is not over yet, a random, unfilled gap will be filled.
     */
    func useJoker() {
        if jokers > 0, !gameOver, let (word, (range, _)) = gaps.filter({ !$1.1 }).random() {
            jokers -= 1
            delegate.jokerUsed()
            fillGap(word: word, range: range)
        }
    }
    
    
    /**
     Sets a flag for this gap that it has been filled, and tells the controller that an input was successful.
     If no unfilled gaps are left, the game is over.
     */
    private func fillGap(word: String, range: NSRange) {
        gaps[word] = (range, true)
        delegate.fillGap(gap: range)
        
        if gaps.values.filter({ !$1 }).isEmpty {
            endGame(win: true)
        }
    }
}


/**
 Used for MVC to communicate back with the controller
 */
public protocol GameDelegate {
    func gameLoaded()
    func loadingFailed()
    func fillGap(gap: NSRange)
    func gameOver(win: Bool)
    func updateTimer(time: Int)
    func jokerUsed()
}


public enum Difficulty: Int {
    case easy
    case medium
    case hard
    
    
    /**
     Returns true if a random value in [0, 100) is lower than a threshold depending on the raw value.
     The higher the difficulty, the higher the chance to return true.
     */
    func pollRandom() -> Bool {
        return Int(arc4random_uniform(100)) < (self.rawValue * 13) + 20
    }
    
    
    /**
     Returns the amount time in seconds available for each gap depending on the raw value.
     */
    func availableTimePerGap() -> Int {
        return 20 - (rawValue * 5)
    }
    
    
    /**
     Returns the total amount of jokers available in each gamemode.
     */
    func amountOfJokers() -> Int {
        return (2 - rawValue) * 2
    }
}


public enum Gamemode: Int {
    case timed
    case sprint
    case free
}


public let descriptions: [AnyHashable: String] = [
    Difficulty.easy: "Wenige Lücken\nca. 15% des Textes",
    Difficulty.medium: "Mehr Lücken\nca. 30% des Textes",
    Difficulty.hard: "Viele Lücken\nca. 40% des Textes",
    Gamemode.timed: "Fülle möglichst viele Lücken\nin vorgegebener Zeit",
    Gamemode.sprint: "Fülle alle Lücken so schnell\nwie möglich",
    Gamemode.free: "Lass dir Zeit und hab Spaß"
]


extension Array {
    /**
     Returns a random entity of this array or nil if it is empty
     */
    public func random() -> Element? {
        if isEmpty {
            return nil
        }
        
        let index: Int = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}
