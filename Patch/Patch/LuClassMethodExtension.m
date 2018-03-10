//
//  LuClassMethodExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuClassMethodExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"


@implementation LuClassMethodExtension

/**
 *  声明 命令
 *
 *  @param command  从中间获取指令
 */
-(void)declare:(NSDictionary *)command {
    NSString* selNameString = command[@"selName"]; // 获得selName
    NSString* clsNameString = command[@"clsName"]; // 获得clsName
    NSNumber* callbackId = command[@"jsFn"];
    if(callbackId == nil) return;
    JSValue* function = [self.context[@"_lufix_callback"] callWithArguments:@[callbackId]]; // 获得function的可执行对象
    __unused Class currentCls = NSClassFromString(clsNameString);
    Class metaCls = objc_getMetaClass(clsNameString.UTF8String);
    if (function != nil) {
        initLUFixJSMethods(metaCls);
        _LUFixJSMethods[metaCls][selNameString] = function;
    }
    SEL  sel = NSSelectorFromString(selNameString);
    if (class_respondsToSelector(metaCls, sel)) {
       
        Method method = class_getInstanceMethod(metaCls, sel);
        IMP originalImp = class_getMethodImplementation(metaCls, sel);
         IMP msgForwardIMP = _objc_msgForward;
        if (class_getMethodImplementation(metaCls, @selector(forwardInvocation:)) != (IMP)__LUFIX_CALLEE__) {
            IMP originalForwardImp = class_replaceMethod(metaCls, @selector(forwardInvocation:), (IMP)__LUFIX_CALLEE__, "v@:@");
            if (originalForwardImp) {
                class_addMethod(metaCls, lufix_aliasForSelector(@selector(forwardInvocation:)), originalForwardImp, "v@:@");
            }
        }
        SEL originalSel = lufix_aliasForSelector(sel);
        if (! class_respondsToSelector(metaCls, originalSel)) {
            class_addMethod(metaCls, originalSel, originalImp, method_getTypeEncoding(method));
        }
        // 将对sel 响应发送到msgForwardIMP当中去了
        class_replaceMethod(metaCls, sel, msgForwardIMP, method_getTypeEncoding(method));
    }
    
    
}




/**
 *   执行代码，alloc/super什么的要搞清楚
 *
 *  @param command
 *
 *  @return  返回值
 */

-(JSValue *)evaluate:(NSDictionary *)command{
    NSString* selNameString = command[@"selName"]; // 获得selName
    NSString* clsNameString = (command[@"className"] == [NSNull null])?nil:command[@"className"]; // 获得clsName
    if (clsNameString == nil) {
        return nil;
    }
    NSArray* args = command[@"arguments"];
    Class instance  = NSClassFromString(clsNameString);
    Class instanceCls = NSClassFromString(clsNameString);
    SEL selector = NSSelectorFromString(selNameString);
    
    NSInvocation *invocation;
    NSMethodSignature* signature = [instanceCls methodSignatureForSelector:selector];
    invocation  = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:instance]; // 设置target
    [invocation setSelector:selector];//设置 sel
    NSUInteger numberOfArguments = signature.numberOfArguments;
    NSArray*   callArguments = args;
    // 暂时不支持可变参数调用
    for (int i = 2; i < numberOfArguments ; i++) {
    
        [JSValue setArgumentWithInvocaiton:invocation withObject:callArguments[i-2] atIndex:i];
    }
    [invocation invoke];
    
    return [JSValue valueOfRetValueAtInvocation:invocation inJSContext:self.context];
}
@end
