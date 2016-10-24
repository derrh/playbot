//
//  Robot.swift
//  playbot
//
//  Created by Derrick Hathaway on 10/22/16.
//  Copyright © 2016 Derrick Hathaway. All rights reserved.
//

import Foundation
import botkit
import Playful
import Alamofire

public class Robot: NSObject {
    
    static func uploadPlayground(named: String, code: String, in channel: Channel, bot: Bot) {
        
        do {
            let code = code
                .replacingOccurrences(of: "”", with: "\"")
                .replacingOccurrences(of: "“", with: "\"")

            let playground = try Playground(named: named, inDirectory: URL.tempDirectory)
            try playground.append(code: code)
            
            print(playground.url)
            
            let zipURL = playground.url.appendingPathExtension("zip")
            let compress = Process()
            compress.launchPath = "/usr/bin/zip"
            compress.currentDirectoryPath = playground.url
                .deletingLastPathComponent()
                .path
            compress.arguments = ["-r", zipURL.path, playground.url.lastPathComponent]
            compress.launch()
            compress.waitUntilExit()
            
            let tokenData = bot.configuration.authToken.data(using: .utf8)!
            let fileNameData = "\(named).playground.zip".data(using: .utf8)!
            let channelData = channel.identifier.value.data(using: .utf8)!
            Alamofire.upload(multipartFormData: { multipart in
                multipart.append(tokenData, withName: "token")
                multipart.append(fileNameData, withName: "filename")
                multipart.append(channelData, withName: "channels")
                multipart.append(zipURL, withName: "file")
            }, to: URL(string: "https://slack.com/api/files.upload")!) { result in
                switch result {
                case .success(let request, _, _):
                    request.responseJSON { response in
                        if case .failure(let error) = response.result {
                            print(error)
                        }
                        try? FileManager.default.removeItem(at: playground.url)
                        try? FileManager.default.removeItem(at: zipURL)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }
    
    static func onMessage(_ m: Channel.MessagePosted, bot: Bot) {
        print("someone said something: \(m.message.text)")
        let snippets = m.message.text.components(separatedBy: "```")
        if snippets.count < 3 {
            print("message does not contain a valid snippet\n\n\(m.message.text)\n\n")
            return
        }
        
        uploadPlayground(named: m.message.user.name ?? "Play", code: snippets[1], in: m.message.channel, bot: bot)
    }
    
    static func onSnippet(_ s: Channel.SnippetPosted, bot: Bot) {
        guard s.file.mimetype == "text/plain" else {
            return print("expected a swift file")
        }
        
        let filename: String
        if !s.file.filename.contains(".swift") || s.file.filename == "-.swift" {
            filename = "Play"
        } else {
            filename = s.file.filename
                .removing(suffix: ".swift", options: .caseInsensitive)
                .replacingOccurrences(of: "_swift", with: "")
        }
        
        var request = URLRequest(url: s.file.downloadURL)
        request.addValue("Bearer \(bot.configuration.authToken)", forHTTPHeaderField: "Authorization")
        
        let download = URLSession.shared.downloadTask(with: request) { location, response, error in
            
            if let location = location,
               let code = try? String(contentsOf: location) {
                uploadPlayground(named: filename, code: code, in: s.channel, bot: bot)
            }
        }
        download.resume()
    }
    
    public class func play(token: String) {
        let main = RunLoop.main
        
        let config = Bot.Configuration(authToken: token, adminToken: nil, pingInterval: 0.5, dataDirectory: URL(fileURLWithPath: "", isDirectory: true))
        
        let bot = Bot(configuration: config)
        bot.on() { m, b in Robot.onMessage(m, bot: b) }
        bot.on() { s, b in Robot.onSnippet(s, bot: b) }
        
        bot.connect()

        main.run()
    }
}
