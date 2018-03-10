//
//  JSValue+LuTypeTransfer.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/6.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "JSValue+LuTypeTransfer.h"
#import <objc/runtime.h>
#import "LuValueCase.h"

#define LU_CONCAT(a,b)  a ## b
#define LU_CONCAT_WRAPPER(a, b)  LU_CONCAT(a, b)

@implementation JSValue (LuTypeTransfer)

+ (uint64_t)uint64_l:(id)value {
    NSString * strval = [NSString stringWithFormat:@"%@",value];
    unsigned long long ullvalue = strtoull([strval UTF8String], NULL, 10);
    return ullvalue;
}

+(void)setArgumentWithInvocaiton:(NSInvocation *)invocation  withObject:(id)obj  atIndex:(NSInteger)index {
    id value = obj;
    // 解包过程
    if ([value isKindOfClass:[LuValueCase class]]) {
        value = [((LuValueCase *)value)decase];
    }
    const char *argumentType  = [invocation.methodSignature getArgumentTypeAtIndex:index];
    switch (argumentType[0] == 'r'? argumentType[1] : argumentType[0]) {
# define LU_CALL_ARG_CONVERT(_typeChar,type, op) \
case _typeChar :{ \
if([value respondsToSelector:@selector(op)]) { \
type _val = [value op]; \
[invocation setArgument:&_val atIndex: index ];\
}\
else {\
NSString *strval = [NSString stringWithFormat:@"%@",value];\
type _val = (type)[JSValue uint64_l: strval]; \
[invocation setArgument:&_val atIndex: index ];\
}\
break;\
}
            
            LU_CALL_ARG_CONVERT(_C_CHR, char, charValue)
            LU_CALL_ARG_CONVERT(_C_UCHR, unsigned char, unsignedCharValue)
            LU_CALL_ARG_CONVERT(_C_SHT, short, shortValue)
            LU_CALL_ARG_CONVERT(_C_USHT, unsigned short, unsignedShortValue)
            LU_CALL_ARG_CONVERT(_C_INT, int, intValue)
            LU_CALL_ARG_CONVERT(_C_UINT, unsigned int, unsignedIntValue)
            LU_CALL_ARG_CONVERT(_C_LNG, long, longValue)
            LU_CALL_ARG_CONVERT(_C_ULNG, unsigned long, unsignedLongValue)
            LU_CALL_ARG_CONVERT(_C_LNG_LNG,long long, longLongValue)
            LU_CALL_ARG_CONVERT(_C_ULNG_LNG,unsigned long long, unsignedLongLongValue)
            LU_CALL_ARG_CONVERT(_C_FLT,float, floatValue)
            LU_CALL_ARG_CONVERT(_C_DBL, double, doubleValue)
            LU_CALL_ARG_CONVERT(_C_BOOL, BOOL, boolValue)
            
        case ':': {
            SEL selector = NSSelectorFromString(value);
            [invocation setArgument:&selector atIndex:index];
            
            break;
        }
        case '{': { // 对struct 类型的支持
            NSString *typeString = [NSString stringWithUTF8String: argumentType];
#define  LU_CALL_ARG_STRUCT(_type, op) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
if (![value isKindOfClass:[JSValue class]]) {\
            value = [JSValue valueWithObject:value inContext:[JSContext new]]; \
        } \
_type _val = [value op]; \
[invocation setArgument:&_val atIndex: index ];\
break; \
}
            
            LU_CALL_ARG_STRUCT(CGRect, toRect)
            LU_CALL_ARG_STRUCT(CGPoint, toPoint)
            LU_CALL_ARG_STRUCT(CGSize, toSize)
            LU_CALL_ARG_STRUCT(NSRange, toRange)
            // todo: 仅支持Rect Point Size Range 类型的转换
            
          
            
//            NSUInteger valueSize = 0;
//            NSGetSizeAndAlignment(argumentType, &valueSize, NULL);
//            unsigned char valueBytes[valueSize];
//            NSValue* value = [NSValue valueWithNonretainedObject:obj];
//            [value getValue:valueBytes];
//            [invocation setArgument:valueBytes atIndex:index];
            break;
        }
        case '*':
        case '^': { //todo: 对指针和block 类型的支持
            
            break;
        }
        case '#': { //todo: 对类类型的支持
            
            break;
        }
        case '@': { // 对对象的支持 直接进行赋值
            #warning 如果传参为null,将转为nil  后续是否增加对NSNull的支持
            if (!value || [value isKindOfClass:[NSNull class]]) {
                value = nil;
            }
            [invocation setArgument:&value atIndex:index];
            break;
        }
        default: { //todo:
            
        }
            break;
    }
    
    
}

    
+(JSValue *) valueOfRetValueAtInvocation:(NSInvocation*)invocation inJSContext:(JSContext *)context {
    //retValue = [JSValue LU_CONCAT_WRAPPER(LU_CONCAT_WRAPPER(valueWith, selector),:) value inContext: context];
    const char *returnType = [invocation.methodSignature methodReturnType];
    NSString* selName = NSStringFromSelector(invocation.selector);
    JSValue *retValue = nil;
    switch (returnType [0] == _C_CONST ? returnType[1]: returnType[0]) {
        case _C_VOID: { // 返回空类型 
            retValue = [JSValue valueWithNullInContext:context];
        }
        break;
        case _C_ID: { // 表明是id 类型
            void *value;
            [invocation getReturnValue:&value];
            id object = nil;
            if ([@[@"alloc",@"new",@"copy",@"mutableCopy"] containsObject:selName]) {
                object = (__bridge_transfer id)value;
            }else{
             object = (__bridge id)value;
            }
            if (object == nil) {
                object = [NSNull null];
            }
            // 对MutableDictionary 和 MutableArray 进行处理
            if ([object isKindOfClass:[NSMutableArray class]] ||[object isKindOfClass:[NSMutableDictionary class]]) {
                object = [[LuValueCase incase:object]jsObject];
            }
            
            retValue = [JSValue valueWithObject:@{
                                                  @"__type": @"instance",
                                                  @"__content": @{@"clsName":NSStringFromClass([object class]),@"objInstance":object}
                                                  } inContext:context];
        }
        break;
            
#define LU_JSVALUE_RETURN_CASE(typeChar, type) \
       case typeChar:{ \
         type value; \
         [invocation getReturnValue: &value];\
         retValue = [JSValue valueWithObject:@(value) inContext:context]; \
         break;\
        }
      
            LU_JSVALUE_RETURN_CASE(_C_CHR, char)
            LU_JSVALUE_RETURN_CASE(_C_UCHR, unsigned char)
            LU_JSVALUE_RETURN_CASE(_C_SHT, short)
            LU_JSVALUE_RETURN_CASE(_C_USHT, unsigned short)
            LU_JSVALUE_RETURN_CASE(_C_INT, int)
            LU_JSVALUE_RETURN_CASE(_C_UINT, unsigned int)
            LU_JSVALUE_RETURN_CASE(_C_LNG, long)
            LU_JSVALUE_RETURN_CASE(_C_ULNG, unsigned long)
            LU_JSVALUE_RETURN_CASE(_C_LNG_LNG, long long)
            LU_JSVALUE_RETURN_CASE(_C_ULNG_LNG, unsigned long long)
            LU_JSVALUE_RETURN_CASE(_C_FLT, float)
            LU_JSVALUE_RETURN_CASE(_C_DBL, double)
            LU_JSVALUE_RETURN_CASE(_C_BOOL, BOOL)
         
        case _C_STRUCT_B: {
            NSString *typeString = [NSString stringWithUTF8String:returnType];
#define LU_JSVALUE_RET_STRUCT(_type, _methodName)                             \
        if ([typeString rangeOfString:@#_type].location != NSNotFound) {   \
            _type value;                                                   \
            [invocation getReturnValue:&value];                            \
            retValue = [JSValue _methodName:value inContext:context]; \
            break;                                                         \
            }
            
          LU_JSVALUE_RET_STRUCT(CGRect, valueWithRect)  // 支持CGRect
          LU_JSVALUE_RET_STRUCT(CGPoint, valueWithPoint) // 支持Point
          LU_JSVALUE_RET_STRUCT(CGSize, valueWithSize) // 支持 Size
          LU_JSVALUE_RET_STRUCT(NSRange, valueWithRange)
         // TODO: 其他struct 扩展内存对其
        }
        case _C_CLASS : {
            Class ret ;
            [invocation getReturnValue:&ret];
     
            retValue = [JSValue valueWithObject:@{
                                                         @"__type": @"class",
                                                         @"__content":@{@"className":NSStringFromClass(ret)}
                                                         } inContext:context];
          
            break;
        }
        
        case _C_PTR: { // 表明返回值是block 怎么映射成js函数是个问题
            
            break;
        }
        default:
        break;
    }
    
    
    return retValue;
}


+(id)valueOfArgumentsAtInvocation:(NSInvocation*)invocation atIndex:(NSInteger)index inJSContext:(JSContext*)context{
    
    NSMethodSignature *signature = invocation.methodSignature;
    const char *argumentType =  [signature getArgumentTypeAtIndex:index];
    switch (argumentType [0] == _C_CONST ? argumentType[1]: argumentType[0]) {
#define LU_JSVALUE_ARG_CASE(typeChar, type) \
case typeChar: {   \
type arg;  \
[invocation getArgument:&arg atIndex:index];    \
return @(arg);\
}
        // 对基础类型的支持
            LU_JSVALUE_ARG_CASE(_C_CHR, char)
            LU_JSVALUE_ARG_CASE(_C_UCHR, unsigned char)
            LU_JSVALUE_ARG_CASE(_C_SHT, short)
            LU_JSVALUE_ARG_CASE(_C_USHT, unsigned short)
            LU_JSVALUE_ARG_CASE(_C_INT, int)
            LU_JSVALUE_ARG_CASE(_C_UINT, unsigned int)
            LU_JSVALUE_ARG_CASE(_C_LNG, long)
            LU_JSVALUE_ARG_CASE(_C_ULNG, unsigned long)
            LU_JSVALUE_ARG_CASE(_C_LNG_LNG, long long)
            LU_JSVALUE_ARG_CASE(_C_ULNG_LNG, unsigned long long)
            LU_JSVALUE_ARG_CASE(_C_FLT, float)
            LU_JSVALUE_ARG_CASE(_C_DBL, double)
            LU_JSVALUE_ARG_CASE(_C_BOOL, BOOL)
        // 对对象的支持
        case _C_ID :{
            __unsafe_unretained id arg;
            [invocation getArgument:&arg atIndex:index];
            if (arg == nil) {
                arg = [NSNull null];
            }
            return arg;
        }
            break;
         // 对结构体的支持 支持基础类型的block
        case _C_STRUCT_B:{
             NSString *typeString = [NSString stringWithUTF8String:argumentType];
            #define LU_JSVALUE_ARG_STRUCT(_type, _methodName) \
            if([typeString rangeOfString:@#_type].location != NSNotFound){\
                _type arg; \
              [invocation getArgument:&arg atIndex:index];    \
              return [JSValue _methodName: arg inContext: context];\
           }
            LU_JSVALUE_ARG_STRUCT(CGRect, valueWithRect)
            LU_JSVALUE_ARG_STRUCT(CGPoint, valueWithPoint)
            LU_JSVALUE_ARG_STRUCT(CGSize, valueWithSize)
            LU_JSVALUE_ARG_STRUCT(NSRange, valueWithRange)
           //todo: 支持其他struct 类型
        }
            break;
        // 对class的支持
        case _C_CLASS : {
            Class arg;
            [invocation getArgument:&arg atIndex:index];
            return @{@"className":NSStringFromClass(arg)};
            break;
        }
        // 对function的支持
        case _C_PTR:
        case _C_CHARPTR:
        {
            break;
        }
        // 对selector的支持
        case _C_SEL:
        {
            SEL selector;
            [invocation getArgument:&selector atIndex:index];
            NSString* selName = NSStringFromSelector(selector);
            return selName;
        }
            
        default:
            break;
    }
    
    return [NSNull null];
    
}

@end




// todo 根据传入的参数转
static id formatJSValueToObjcValue(JSValue *jsVal){
    
    return jsVal;
}
