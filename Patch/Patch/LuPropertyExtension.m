//
//  LuPropertyExtension.m
//  JSPatchDemo
//
//  Created by Jaime on 2017/6/26.
//  Copyright © 2017年 lufax. All rights reserved.
//

#import "LuPropertyExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"
#import "LuValueCase.h"

@implementation LuPropertyExtension

-(JSValue *)evaluate:(NSDictionary *)command {
    id obj = command[@"object"];
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        obj = nil;
    }
    if (obj == nil) return [JSValue valueWithBool:NO inContext:self.context];
    
    NSString* typeString = command[@"type"];         // 获得type
    NSString* propNameString =[NSString stringWithFormat:@"%@",command[@"propName"]]; // 获得propName
    id value = command[@"value"];                    // 获得value
    if ([typeString isEqualToString:@"setter"]) {
        return [self evaluateSet:obj propName:propNameString value:value];
    }else {
        return [self evaluateGet:obj propName:propNameString];
    }
}


//执行setter
-(JSValue *)evaluateSet:(id)obj propName:(NSString*)propNameString value:(id)value {
    BOOL isSuccess = YES;
   // 这段代码是为了同步js对象到Mutable对象的赋值
    if ([obj isKindOfClass:[LuValueCase class]]) {
        id innerVal = [((LuValueCase *) obj)decase];
        if ([innerVal isKindOfClass:[NSMutableDictionary class]]) {
            if (value != nil && value != [NSNull null]) {
                [innerVal setObject:value forKey:propNameString];
            }else{
                [innerVal removeObjectForKey:propNameString];
            }
        }
        return [JSValue valueWithBool:YES inContext:self.context];
    }
    
    Class instanceCls = [obj class];
    objc_property_t prop = class_getProperty(instanceCls, propNameString.UTF8String);
    if (prop != nil) {
        const char * attrs = property_getAttributes(prop);
        NSString *propertyAttributes = @(attrs);     //T@"NSString",&,N,GgetAge,SsetMyAge:,V_age
        NSArray *attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        if ([attributeItems containsObject:@"R"]) {      // 只读属性直接注入
            [obj setValue:value forKeyPath:propNameString];
        } else {
            NSString *customSetter = [self getCustomSelName:attributeItems regexStr:@"^S([\\w:]+)"];
            SEL selector;
            if (customSetter.length > 0) {
                selector = NSSelectorFromString(customSetter);
            } else {
                NSString *selectorStr =[[propNameString substringToIndex:1].uppercaseString stringByAppendingString:[propNameString substringFromIndex:1]];
                selectorStr = [NSString stringWithFormat:@"set%@:",selectorStr];
                selector = NSSelectorFromString(selectorStr);
                if (!class_respondsToSelector(instanceCls, selector)) {
                    // 如果没有该属性，直接通过ivar来操作
                }
            }
            
            NSInvocation *invocation;
            NSMethodSignature* signature = [instanceCls instanceMethodSignatureForSelector:selector];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:obj];
            [invocation setSelector:selector];
            //NSUInteger numberOfArguments = signature.numberOfArguments;
            [JSValue setArgumentWithInvocaiton:invocation withObject:value atIndex:2];
            [invocation invoke];
        }
        
    }else {
        // 补充类似于UIView的frame 或者 backgroundColor这种属性列表没有存放的类
        if (propNameString.length == 0) {
          isSuccess = NO;
        }else{
            
            NSString* selectorString = [NSString stringWithFormat:@"set%@:",[[propNameString substringToIndex:1].uppercaseString stringByAppendingString:[propNameString substringFromIndex:1]]];
            SEL sel = NSSelectorFromString(selectorString);
            if (class_respondsToSelector(instanceCls, sel)){
                NSMethodSignature* signature = [instanceCls instanceMethodSignatureForSelector:sel];
                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:obj];
                [invocation setSelector:sel];
                [JSValue setArgumentWithInvocaiton:invocation withObject:value atIndex:2];
                [invocation invoke];
            }else{
                isSuccess = NO;
            }
        }
        
        
    }
    
    return [JSValue valueWithBool:isSuccess inContext:self.context];
}


//执行getter
-(JSValue *)evaluateGet:(id)obj propName:(NSString*)propNameString {
    
    Class instanceCls = [obj class];
    objc_property_t prop = class_getProperty(instanceCls, propNameString.UTF8String);
    // return [JSValue valueWithNullInContext:self.context];
    if (prop == nil){
        SEL sel = NSSelectorFromString(propNameString);
        if (class_respondsToSelector(instanceCls, sel)) {
         NSMethodSignature* signature = [instanceCls instanceMethodSignatureForSelector:sel];
         NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:obj];
        [invocation setSelector:sel];
        [invocation invoke];
        return [JSValue valueOfRetValueAtInvocation:invocation inJSContext:self.context];
        }else{
            return [JSValue valueWithNullInContext:self.context];
        }
 
    }
    
    const char *attrs = property_getAttributes(prop);
    NSString *propertyAttributes = @(attrs);    // T@"NSString",&,N,GgetAge,SsetMyAge:,V_age
    NSArray *attributeItems = [propertyAttributes componentsSeparatedByString:@","];
    
    NSString *customGetter = [self getCustomSelName:attributeItems regexStr:@"^G([\\w]+)"];
    SEL selector;
    if (customGetter.length > 0) {
        selector = NSSelectorFromString(customGetter);
    } else {
        selector = NSSelectorFromString(propNameString);
    }
    
    NSInvocation *invocation;
    NSMethodSignature* signature = [instanceCls instanceMethodSignatureForSelector:selector];
    invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:obj];
    [invocation setSelector:selector];
    
    [invocation invoke];
    // 判断property是否是dic 类型
//    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^T@\"(\\w+)\"" options:kNilOptions error:nil];
//    NSString* typeString = attributeItems[0];
//    NSTextCheckingResult* matchType = [regex firstMatchInString:typeString options:kNilOptions range:NSMakeRange(0, typeString.length)];
//    if (matchType != nil) {
//         NSRange matchRange = [matchType rangeAtIndex:1];
//        NSString* matchedString = [typeString substringWithRange:matchRange];
//        //如果是对象MutableDictionary需要对访问进行处理
//        if ([matchedString isEqualToString:@"NSMutableDictionary"]) {
//            void *val;
//            [invocation getReturnValue:&val];
//            id object = (__bridge id) val;
//            if (object == nil) {
//                return [JSValue valueWithNullInContext:self.context];
//            }
//            LuValueCase* valCase = [LuValueCase incase:object];
//            NSDictionary* wrapper = @{@"object":object,@"case":valCase,@"__wrapper":@(YES)};
//            return [JSValue valueWithObject:@{
//                                                  @"__type": @"instance",
//                                                  @"__content": @{@"clsName":NSStringFromClass([object class]),@"objInstance":wrapper}
//                                                  } inContext:self.context];
//            
//        }
//    }
    // 根据returnType 判断返回值并且封装成JSValue 返回到前端
    return [JSValue valueOfRetValueAtInvocation:invocation inJSContext:self.context];
}


//获取自定义 setter/getter 函数名
- (NSString *)getCustomSelName:(NSArray*)attributeItems regexStr:(NSString*)regexStr {
    NSString *customSelName = nil;
    
    for (NSString* ele in attributeItems) {
        NSError *error;
        // 创建NSRegularExpression对象并指定正则表达式
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:regexStr
                                      options:0
                                      error:&error];
        if (!error) {
            // 获取特定字符串的范围
            NSTextCheckingResult *match = [regex firstMatchInString:ele
                                                            options:0
                                                              range:NSMakeRange(0, [ele length])];
            if (match) {
                customSelName = [ele substringWithRange:match.range];
                customSelName = [customSelName substringFromIndex:1];
                NSLog(@"%@",customSelName);
                break;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }
    return customSelName;
}

@end
