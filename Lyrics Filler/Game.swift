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
                timer.invalidate()
                gameOver = true
                delegate.gameOver(win: false)
            }
        }
    }
    
    
    private func generateGaps() {
        gaps = [:]
        let lyrics = NSString(string: self.lyrics)
        for word in lyrics.components(separatedBy: .whitespacesAndNewlines) {
            guard word.lengthOfBytes(using: .utf8) >= 4,
                !gaps.keys.contains(word),
                word.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil,
                difficulty.pollRandom()
                else {
                continue
            }
            
            gaps[word.lowercased()] = (lyrics.range(of: word), false)
        }
    }
    
    
    func exit() {
        timer.invalidate()
        startTime = nil
        gameOver = true
        delegate.close()
    }
    
    
    func receiveUserInput(_ text: String) {
        for (word, (range, filled)) in gaps {
            if !filled, text.caseInsensitiveCompare(word) == .orderedSame {
                fillGap(word: word, range: range)
            }
        }
    }
    
    
    func useJoker() {
        if jokers > 0, !gameOver, let (word, (range, _)) = gaps.filter({ !$1.1 }).random() {
            jokers -= 1
            delegate.jokerUsed()
            fillGap(word: word, range: range)
        }
    }
    
    
    private func fillGap(word: String, range: NSRange) {
        gaps[word] = (range, true)
        delegate.successfulInput(gap: range)
        
        if gaps.values.filter({ !$1 }).isEmpty {
            timer.invalidate()
            gameOver = true
            delegate.gameOver(win: true)
        }
    }
}


public protocol GameDelegate {
    func gameLoaded()
    func loadingFailed()
    func successfulInput(gap: NSRange)
    func close()
    func gameOver(win: Bool)
    func updateTimer(time: Int)
    func jokerUsed()
}


public enum Difficulty: Int {
    case easy
    case medium
    case hard
    
    func pollRandom() -> Bool {
        return Int(arc4random_uniform(100)) < (self.rawValue * 13) + 20
    }
    
    func availableTimePerGap() -> Int {
        return 20 - (rawValue * 5)
    }
    
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
    public func random() -> Element? {
        let index: Int = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}
