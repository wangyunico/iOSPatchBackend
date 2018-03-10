//
//  LuBlockExtension.m
//  JSPatchDemo
//
//  Created by Jaime on 2017/7/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuBlockExtension.h"
#import <objc/runtime.h>
#import "LuBlockWrapper.h"

@implementation LuBlockExtension

-(JSValue *)evaluate:(NSDictionary *)command {
    
    NSString *typeEncoding = command[@"typeEncoding"]?:@"";
    if (typeEncoding.length > 0) {
        NSNumber* callbackId = command[@"jsFn"];
        if(callbackId == nil) return nil;
        JSValue *jsFunction = [self.context[@"_lufix_callback"] callWithArguments:@[callbackId]];
        
        LuBlockWrapper *blockWrapper = [[LuBlockWrapper alloc]initWithTypeString:typeEncoding callbackFunction:jsFunction inContext:self.context];
        return [JSValue valueWithObject:[((__bridge id)[blockWrapper blockPointer]) copy] inContext:self.context];  //注：此处copy 是解决block嵌套时加的
        //return [JSValue valueWithObject:(__bridge id)[blockWrapper blockPointer] inContext:self.context];
    }
    return nil;
}

- (void)dealloc {
    //NSLog(@"delloc");
}
@end
