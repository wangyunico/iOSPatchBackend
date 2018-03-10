//
//  LuARCExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/7/21.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuARCExtension.h"

@implementation LuARCExtension



-(JSValue *)evaluate:(NSDictionary *)command {
    id obj = command[@"object"];
    NSString* type = command[@"type"];
    if ([type isEqualToString:@"weak"]) {
     return  [JSValue valueWithObject:[self weakify:obj] inContext:self.context];
    }else if ([type isEqualToString:@"strong"]){
        return [JSValue valueWithObject:[self strongify:obj] inContext:self.context];
    }
    return [JSValue valueWithObject:obj inContext:self.context];
}



-(id)weakify:(id)value {
    __weak id weakValue = value;
    return weakValue;
}


-(id)strongify:(id)value{
    id strongValue = value;
    return strongValue;
}

@end
