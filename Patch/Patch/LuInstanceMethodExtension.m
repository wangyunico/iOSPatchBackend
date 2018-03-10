//
//  LuInstanceMethodExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuInstanceMethodExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"


@interface LuInstanceMethodExtension ()

@end

@implementation LuInstanceMethodExtension





/**
 *   声明实例方法
 *
 *  @param command  解析命令
 */
-(void)declare:(NSDictionary *)command {
    NSString* selNameString = command[@"selName"]; // 获得selName
    NSString* clsNameString = command[@"clsName"]; // 获得clsName
    NSNumber* callbackId = command[@"jsFn"];
    if(callbackId == nil) return;
    JSValue* function = [self.context[@"_lufix_callback"] callWithArguments:@[callbackId]]; // 获得function的可执行对象
    Class currCls = NSClassFromString(clsNameString);
    SEL  sel = NSSelectorFromString(selNameString);
    if (function != nil) {
        initLUFixJSMethods(currCls);
        _LUFixJSMethods[currCls][selNameString] = function;
    }
    if (class_respondsToSelector(currCls, sel)) {
       // 要进行overide
        Method method = class_getInstanceMethod(currCls, sel);
        IMP originalImp = class_getMethodImplementation(currCls, sel);
        IMP msgForwardIMP = _objc_msgForward;
        if (class_getMethodImplementation(currCls, @selector(forwardInvocation:)) != (IMP)__LUFIX_CALLEE__) {
            IMP originalForwardImp = class_replaceMethod(currCls, @selector(forwardInvocation:), (IMP)__LUFIX_CALLEE__, "v@:@");
            if (originalForwardImp) {
                class_addMethod(currCls, lufix_aliasForSelector(@selector(forwardInvocation:)), originalForwardImp, "v@:@");
            }
        }
        SEL originalSel = lufix_aliasForSelector(sel);
        if (! class_respondsToSelector(currCls, originalSel)) {
            class_addMethod(currCls, originalSel, originalImp, method_getTypeEncoding(method));
        }
        // 将对sel 响应发送到msgForwardIMP当中去了
        class_replaceMethod(currCls, sel, msgForwardIMP, method_getTypeEncoding(method));
    }else{
        
        NSLog(@"对一个%@不存在的函数%@修改",clsNameString,selNameString);
        // todo: 是否需要新增函数
        // 当前类协议是否支持这些方法，如果支持则签名采用协议的
        
    }

    
}


-(JSValue *)evaluate:(NSDictionary *)command {
    NSString* selNameString = command[@"selName"]; // 获得selName
    id instance = command[@"object"]; //获得instance的名称
    NSArray* args = command[@"arguments"];
    Class  instanceCls = nil;
    id obj = instance;
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        obj = nil;
    }
    if ( obj!=nil) {
        instanceCls = [obj class];
    }else{
        return [JSValue valueWithNullInContext:self.context];
    }
   
    SEL selector = NSSelectorFromString(selNameString);
    NSInvocation *invocation;
    NSMethodSignature* signature = [instance methodSignatureForSelector:selector];
    invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:obj];
    [invocation setSelector:selector];
    // 根据 Class 的实例方法获取参数类型解析args
    NSUInteger numberOfArguments = signature.numberOfArguments;
    NSArray*   callArguments = args;
    // 暂时不支持可变参数调用
    for (int i = 2; i < numberOfArguments ; i++) {
     
        [JSValue setArgumentWithInvocaiton:invocation withObject:callArguments[i-2] atIndex:i];
    }
    [invocation invoke];
    // 根据returnType 判断返回值并且封装成JSValue 返回到前端
    return [JSValue valueOfRetValueAtInvocation:invocation inJSContext:self.context];
}

@end
