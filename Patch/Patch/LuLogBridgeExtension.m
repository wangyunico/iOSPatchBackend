//
//  LuLogBridgeExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/26.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuLogBridgeExtension.h"
#import "LuValueCase.h"
@implementation LuLogBridgeExtension





-(JSValue*)evaluate:(NSDictionary *)command{
    
    NSArray* args = command[@"info"];
    
    NSString* logString = @"";
    for (id param in args) {
        id tmp = param;
        if([param isKindOfClass:[LuValueCase class]]){
            tmp = [((LuValueCase*)param) decase];
        }
        logString = [NSString stringWithFormat:@"%@ %@",logString,tmp];
    }
    if (logString.length > 0) {
        NSLog(@"lufix: %@", logString);
    }
    return [JSValue valueWithNullInContext:self.context];
}

@end
