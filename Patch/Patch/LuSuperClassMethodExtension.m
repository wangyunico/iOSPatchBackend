//
//  LuSuperClassMethodExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/26.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuSuperClassMethodExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"


@implementation LuSuperClassMethodExtension


-(JSValue *)evaluate:(NSDictionary *)command{
    NSString* selNameString = command[@"selName"]; // 获得selName
    NSString* className = command[@"className"]; //获得instance的名称
    NSArray* args = command[@"arguments"];
    Class  instanceCls = NSClassFromString(className);
    // 1 根据instance 判断出类别，获得实例
    if (instanceCls == nil ) {
        return [JSValue valueWithNullInContext:self.context];
    }
    
    SEL selector = NSSelectorFromString(selNameString);
    NSInvocation *invocation;
    NSMethodSignature* signature = [instanceCls methodSignatureForSelector:selector];
    invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:instanceCls];
    // 表示superClass,为之新增super的Class方法
    Class superCls = class_getSuperclass(instanceCls);
    NSString* superSelName = [NSString stringWithFormat:@"SUPER_%@",selNameString];
    SEL superSelector = NSSelectorFromString(superSelName);
    Method superMethod = class_getClassMethod(superCls, selector);
    IMP superIMP = method_getImplementation(superMethod);
    Class MetaCls = objc_getMetaClass(className.UTF8String);
    class_addMethod(MetaCls, superSelector, superIMP, method_getTypeEncoding(superMethod));
    [invocation setSelector:superSelector];
    // 根据 Class 的实例方法获取参数类型解析args
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
