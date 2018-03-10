//
//  LuAddInstanceMethodExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/7/13.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuAddInstanceMethodExtension.h"

@implementation LuAddInstanceMethodExtension





-(void)declare:(NSDictionary *)command{
    NSString* selName = command[@"selName"];
    NSString* typeEncodings = command[@"type"];
    NSNumber* callbackId = command[@"jsFn"];
    NSString* className = command[@"clsName"];
   JSValue* function = [self.context[@"_lufix_callback"] callWithArguments:@[callbackId]];
    if (function == nil) return;
    Class clazz = NSClassFromString(className);
    SEL  sel = NSSelectorFromString(selName);
    if (class_respondsToSelector(clazz, sel))return;
    initLUFixJSMethods(clazz);
     _LUFixJSMethods[clazz][selName] = function;
    if (class_getMethodImplementation(clazz, @selector(forwardInvocation:)) != (IMP)__LUFIX_CALLEE__) {
        IMP originalForwardImp = class_replaceMethod(clazz, @selector(forwardInvocation:), (IMP)__LUFIX_CALLEE__, "v@:@");
        if (originalForwardImp) {
            class_addMethod(clazz, lufix_aliasForSelector(@selector(forwardInvocation:)), originalForwardImp, "v@:@");
        }
    }
 
   class_addMethod(clazz, sel, _objc_msgForward, [self getTypeEncoding:typeEncodings]);
}


@end
