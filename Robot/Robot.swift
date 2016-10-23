//
//  Robot.swift
//  playbot
//
//  Created by Derrick Hathaway on 10/22/16.
//  Copyright © 2016 Derrick Hathaway. All rights reserved.
//

import Foundation
import botkit

public class Robot: NSObject {
    
    public class func play(token: String) {
        let main = RunLoop.main
        
        let config = Bot.Configuration(authToken: token, adminToken: nil, pingInterval: 0.5, dataDirectory: URL(fileURLWithPath: "", isDirectory: true))
        
        let bot = Bot(configuration: config)
        bot.on() { (m: Channel.MessagePosted, b: Bot) in
            print("someone said something: \(m.message.text)")
            let snippets = m.message.text.components(separatedBy: "```")
            for snippet in snippets {
                if snippet == "```" { continue }
                print("    \(snippet)")
            }
            
            let post = Channel.PostMessage(channel: m.message.channel, message: "Hi!", as: "Play")
            b.execute(action: post, completion: {_ in })
        }
        
        bot.connect()

        main.run()
    }
}
