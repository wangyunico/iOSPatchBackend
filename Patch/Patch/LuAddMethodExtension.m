//
//  LuAddMethodExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/7/13.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuAddMethodExtension.h"

@implementation LuAddMethodExtension


-(const char *)getTypeEncoding:(NSString*)jsEncoding{
    NSArray* encodings = [jsEncoding componentsSeparatedByString:@","];
    NSString* initial = [NSString stringWithFormat:@"%@@:",encodings[0]];
    for(int i = 1; i < encodings.count; i++){
        initial = [initial stringByAppendingString:encodings[i]];
    }
    return  initial.UTF8String;
}

@end
