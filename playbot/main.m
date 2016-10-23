//
//  main.m
//  playbot
//
//  Created by Derrick Hathaway on 10/22/16.
//  Copyright © 2016 Derrick Hathaway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Robot/Robot.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *token = [[NSProcessInfo processInfo] environment][@"PLAYBOT_TOKEN"];
        if (token == nil) {
            NSLog(@"expected PLAYBOT_TOKEN=<slack token> environment variable");
        } else {
            [Robot playWithToken:token];
        }
    }
    return 0;
}
