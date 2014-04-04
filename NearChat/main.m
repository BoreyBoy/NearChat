//
//  main.m
//  NearChat
//
//  Created by BOREY on 14-3-26.
//  Copyright (c) 2014年 ctrip. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        @try {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception.callStackSymbols);
        }
        @finally {
            
        }
    }
}
