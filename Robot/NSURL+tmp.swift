//
//  NSURL+tmp.swift
//  play
//
//  Created by Derrick Hathaway on 10/21/16.
//  Copyright © 2016 Derrick Hathaway. All rights reserved.
//

import Foundation

public extension URL {
    static var tempDirectory: URL {
        let tmplet = NSURL(fileURLWithPath: "/tmp/play-XXXXXXXXXXXXXXXX")
        var dirBytes = [Int8](repeating: 0, count: Int(PATH_MAX))
        guard tmplet.getFileSystemRepresentation(&dirBytes, maxLength: dirBytes.count) else { fatalError() }
        
        guard let dir = mkdtemp(&dirBytes) else { exit(-1) }
        return URL(fileURLWithPath: String(cString: UnsafePointer<CChar>(dir), encoding: String.Encoding.utf8)!)
    }
}
