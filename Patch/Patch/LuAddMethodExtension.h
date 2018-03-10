//
//  LuAddMethodExtension.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/7/13.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuFixBaseExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"

@interface LuAddMethodExtension : LuFixBaseExtension






-(const char *)getTypeEncoding:(NSString*)jsEncoding;
@end
