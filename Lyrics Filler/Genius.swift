//
//  Genius.swift
//  Lyrics Filler
//
//  Created by Torben Schmitz on 11.06.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//
//  Genius API documentation: https://docs.genius.com/
//

import Foundation
import SwiftSoup


public class Genius {
    private let accessToken: String
    
    /*
     Initializes the Genius instance with the access token required to query data from the Genius API
     */
    public init(accessToken: String) {
        self.accessToken = accessToken
    }

    
    public func search(query: String, completionHandler: @escaping (Array<GeniusSong>?, Error?) -> Void) {
        var params = [
            "q": query
        ]
        
        guard let request = createAPIRequest(route: "/search", params: &params) else {
            completionHandler(nil, APIAccessError.malformedURL); return
        }
        
        let wrapper = wrapCompletionHandler(completionHandler: completionHandler) { data in
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response = json?["response"] as? [String: Any],
                let hits = response["hits"] as? [[String: Any]] else {
                return nil
            }
            
            var songs: [GeniusSong] = []
            
            for hit in hits {
                if (hit["type"] as? String ?? "").compare("song") == .orderedSame,
                    let song = GeniusSong(json: hit["result"] as? [String: Any] ?? [:]) {
                        songs.append(song)
                }
            }
            
            return songs
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: wrapper).resume()
    }
    
    
    public func getLyrics(song: GeniusSong, completionHandler: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: song.lyricsUrl) else {
            completionHandler(nil, APIAccessError.malformedURL); return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let wrapper = wrapCompletionHandler(completionHandler: completionHandler) { data in
            do {
                let doc = try SwiftSoup.parse(String(data: data, encoding: .utf8)!)
                let lyricsElement = try doc.getElementsByClass("lyrics").first()!
                for lineBreak in try lyricsElement.getElementsByTag("br") {
                    try lineBreak.text("<br>")
                }
                let text = try lyricsElement.text()
                return text.trimHTML()
            } catch {
                return nil
            }
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: wrapper).resume()
    }
    
    
    /*
     This method forms a URL with the root location of the Genius API and the desired route, including parameters.
     The result a configured URLRequest ready to be used in a data task.
     */
    private func createAPIRequest(route: String, params: inout [String: String]) -> URLRequest? {
        guard let url = URL(string: "https://api.genius.com\(route)?\(params.stringFromHttpParameters())") else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpMethod = "GET"
        return urlRequest
    }
}


/*
 This method returns a completion handler suitable for data tasks.
 It automatically handled errors and forwards them to an existing custom completion handler (completionHandler).
 If no errors occur, the fetched data is passed to a data converter (dataConverter), in order to pass the result to the completionHandler.
 */
private func wrapCompletionHandler<T>(completionHandler: @escaping (T?, Error?) -> Void, _ dataConverter: @escaping (Data) -> T?) -> (Data?, URLResponse?, Error?) -> Void {
    return { data, response, error in
        guard error == nil else {
            completionHandler(nil, error!); return
        }
        
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else {
            completionHandler(nil, APIAccessError.httpStatus(code: code)); return
        }
        
        guard let data = data else {
            completionHandler(nil, APIAccessError.missingData); return
        }
        
        guard let convertedData = dataConverter(data) else {
            completionHandler(nil, APIAccessError.dataConversionFailed); return
        }
        
        completionHandler(convertedData, nil)
    }
}


/*
 This struct represents a song with associated metadata
 */
public struct GeniusSong {
    init?(json: [String: Any]) {
        guard let id = json["id"] as? Int,
            let title = json["full_title"] as? String,
            let lyricsUrl = json["url"] as? String,
            let thumbnailUrl = json["header_image_thumbnail_url"] as? String else {
                return nil
        }
        
        self.id = id
        self.title = title
        self.lyricsUrl = lyricsUrl
        self.thumbnailUrl = thumbnailUrl
    }
    
    public let id: Int
    public let title: String
    public let lyricsUrl: String
    public let thumbnailUrl: String
    
}


extension Dictionary {
    
    /*
     Encodes keys and values to match the RFC 3986 for URI syntax and returns a string ready to be used in a URL
     */
    func stringFromHttpParameters() -> String {
        let parameters = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let percentEscapedValue = (value as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameters.joined(separator: "&")
    }
}


extension String {
    
    func trimHTML() -> String {
        var result = String()
        for line in self.components(separatedBy: "<br>") {
            result.append("\(line.trimmingCharacters(in: .whitespaces))\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


/*
 Custom error types
 */
public enum APIAccessError : Error {
    case malformedURL
    case missingData
    case dataConversionFailed
    case httpStatus(code: Int)
}
