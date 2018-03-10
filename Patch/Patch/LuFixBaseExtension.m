//
//  LuFixBaseExtension.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuFixBaseExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSValue+LuTypeTransfer.h"
// 不要改动，因为js中orginal方的的替换是会提成这个前缀
static NSString *const LufixMessagePrefix = @"_lufix";

NSMutableDictionary* _LUFixJSMethods = nil;

@interface LuFixBaseExtension ()

@end


@implementation LuFixBaseExtension



-(id)initWithJSContext:(JSContext *)context {
    if (self = [super init]) {
        self.context = context;
    }
    return self;
}



/**
 *   为了swizzle的函数，参考了Aspect, 反震forwardInvocation IMP的结构
 *
 *  @param assignSlf
 *  @param selector
 *  @param invocation
 */
 void __LUFIX_CALLEE__(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation) {
   
    SEL originalSelector = invocation.selector;
    SEL aliasSelector = lufix_aliasForSelector(originalSelector);
    id slf = assignSlf;
    NSMethodSignature *methodSignature = invocation.methodSignature;
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    // 取到jsValue
    JSValue* fn = nil;
    Class cls = object_getClass(assignSlf);
    while (!fn) {
        if (!cls) {
            break;
        }
        fn = _LUFixJSMethods[cls][NSStringFromSelector(originalSelector)];
        cls = class_getSuperclass(cls);
    }
    if (!fn) {
        // todo : 执行原来的调用直接
        evalOriginalForwardInvocation(slf, selector, invocation);
        return;
    }
    // 将参数提出来，并且转换到js的类型进行调用
    JSContext* currentContext = [LuScriptLoader defaultLoader].context;
    NSMutableArray* argList = @[].mutableCopy;
    if ( [slf class] == slf) {
        [argList addObject:@{@"__type":@"class",@"__content":@{@"className":NSStringFromClass(slf)}} ];
    }else{ //todo: 暂时作为类对象，以后扩展代理对象
         [argList addObject:@{@"__type":@"instance",@"__content":@{@"clsName":NSStringFromClass([slf class]),@"objInstance":slf}} ]; }
    for (int i = 2; i < numberOfArguments; i++) {
        [argList addObject:[JSValue valueOfArgumentsAtInvocation:invocation atIndex:i inJSContext:currentContext]];
    }
   
#define LU_CallJS_Ret_Value \
 JSValue *jsval; \
    jsval = [fn callWithArguments:argList];
    
# define LU_Call_RET_CASE(_typeChar,type, op)\
  case _typeChar:{\
    LU_CallJS_Ret_Value\
    type ret = [[jsval toObject] op];\
     [invocation setReturnValue:&ret];\
     break;\
    }
    
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    switch (returnType [0] == _C_CONST ? returnType[1]: returnType[0]) {
    LU_Call_RET_CASE(_C_CHR, char, charValue)
    LU_Call_RET_CASE(_C_UCHR, unsigned char, unsignedCharValue)
    LU_Call_RET_CASE(_C_SHT, short, shortValue)
    LU_Call_RET_CASE(_C_USHT, unsigned short, unsignedShortValue)
    LU_Call_RET_CASE(_C_INT, int, intValue)
    LU_Call_RET_CASE(_C_UINT, unsigned int, unsignedIntValue)
    LU_Call_RET_CASE(_C_LNG, long, longValue)
    LU_Call_RET_CASE(_C_ULNG, unsigned long, unsignedLongValue)
    LU_Call_RET_CASE(_C_LNG_LNG,long long, longLongValue)
    LU_Call_RET_CASE(_C_ULNG_LNG,unsigned long long, unsignedLongLongValue)
    LU_Call_RET_CASE(_C_FLT,float, floatValue)
    LU_Call_RET_CASE(_C_DBL, double, doubleValue)
    LU_Call_RET_CASE(_C_BOOL, BOOL, boolValue)
   
    case _C_VOID: {
         LU_CallJS_Ret_Value
        break;
        }
    case _C_STRUCT_B: {
    NSString *typeString = [NSString stringWithUTF8String:returnType];
#define LU_Call_RET_STRUCT(_type, _method) \
 if ([typeString rangeOfString:@#_type].location != NSNotFound) {   \
     LU_CallJS_Ret_Value \
     _type value = [jsval _method]; \
     [invocation setReturnValue:&value];\
     break; \
}
        LU_Call_RET_STRUCT(CGRect, toRect);
        LU_Call_RET_STRUCT(CGPoint, toPoint);
        LU_Call_RET_STRUCT(CGSize, toSize);
        LU_Call_RET_STRUCT(NSRange, toRange);
 // todo 对struct的支持，返回的是js对象对象的支持
//        NSUInteger valueSize = 0;
//        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
//        char valueBytes[valueSize];
        LU_CallJS_Ret_Value;
        id fakeObj = nil;
        [invocation setReturnValue:&fakeObj];
      
        break;
        }
    case _C_ID: {
        LU_CallJS_Ret_Value
        id __autoreleasing ret = [jsval toObject];
        [invocation setReturnValue:&ret];
        break;
        }       
    case _C_CLASS: {
          LU_CallJS_Ret_Value
          Class ret ;
        ret = [[jsval toObject] class];
        [invocation setReturnValue:&ret];
        break;
        }
    case _C_PTR: {
        // todo
          LU_CallJS_Ret_Value
        }
    case _C_SEL: {
         //todo
         LU_CallJS_Ret_Value
        }
    case _C_CHARPTR: {
        //todo
         LU_CallJS_Ret_Value
        }
    }
}



static void evalOriginalForwardInvocation(id slf, SEL selector, NSInvocation *invocation ) {
    SEL originalMsgForwardSelector = lufix_aliasForSelector(@selector(forwardInvocation:));
    if ([slf respondsToSelector:originalMsgForwardSelector]) {
        NSMethodSignature *methodSignature = [slf methodSignatureForSelector:originalMsgForwardSelector];
        if (!methodSignature) {
            return;
        }
        NSInvocation* forwardInv = [NSInvocation invocationWithMethodSignature:methodSignature];
        [forwardInv setTarget:slf];
        [forwardInv setSelector:originalMsgForwardSelector];
        [forwardInv setArgument:&invocation atIndex:2];
        [forwardInv invoke];
    }else{
        Class superCls = [[slf class] superclass];
        Method superForwardMethod = class_getInstanceMethod(superCls, @selector(forwardInvocation:));
        void (*superForwardIMP)(id, SEL, NSInvocation *);
        superForwardIMP = (void (*)(id, SEL, NSInvocation *))method_getImplementation(superForwardMethod);
        superForwardIMP(slf, @selector(forwardInvocation:), invocation);
    }
}


 SEL lufix_aliasForSelector(SEL selector) {
    NSCParameterAssert(selector);
    return NSSelectorFromString([LufixMessagePrefix stringByAppendingFormat:@"%@", NSStringFromSelector(selector)]);
}


 void initLUFixJSMethods(Class cls) {
    if (_LUFixJSMethods == nil) {
        _LUFixJSMethods = [[NSMutableDictionary alloc]init];
    }
    if (! _LUFixJSMethods[cls]) {
        _LUFixJSMethods[(id<NSCopying>)cls] = @{}.mutableCopy;
    }
}

@end
