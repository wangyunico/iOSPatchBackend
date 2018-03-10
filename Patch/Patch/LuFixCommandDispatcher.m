//
//  LuFixCommandDispatcher.m
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuFixCommandDispatcher.h"
#import "LuFixBaseExtension.h"
#import "LuClassMethodExtension.h"
#import "LuInstanceMethodExtension.h"
#import "LuSuperMethodExtension.h"
#import "LuSuperClassMethodExtension.h"
#import "LuLogBridgeExtension.h"
#import "LuPropertyExtension.h"
#import "LuBlockExtension.h"
#import "LuAddInstanceMethodExtension.h"
#import "LuAddClassMethodExtension.h"
#import "LuARCExtension.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface LuFixCommandDispatcher ()

@property (nonatomic,weak)LuScriptLoader *scriptLoader;
// extension 类注册的map
@property (nonatomic,strong) NSMutableDictionary *extClsRegisterMap;
// extensionInstance的map
@property (nonatomic,strong) NSMutableDictionary* extInstanceMap;
@end


@implementation LuFixCommandDispatcher




-(id)initWithLuScriptLoader:(LuScriptLoader *)scriptLoader {
    
    if (self = [super init]) {
        self.scriptLoader = scriptLoader;
        self.extClsRegisterMap = @{}.mutableCopy; //
        self.extInstanceMap = @{}.mutableCopy;
        [self registerdefaultExtension];
    }
    
    return self;
}




-(void)registerdefaultExtension {
    // 注册响应方法
    [self registerExtensionClass:[LuInstanceMethodExtension class] withIdentifier:@"method_i"];
    [self registerExtensionClass:[LuClassMethodExtension class] withIdentifier:@"method_c"];
    [self registerExtensionClass:[LuSuperMethodExtension class] withIdentifier:@"super_i"];
    [self registerExtensionClass:[LuSuperClassMethodExtension class] withIdentifier:@"super_c"];
    [self registerExtensionClass:[LuLogBridgeExtension class] withIdentifier:@"log_i"];
    [self registerExtensionClass:[LuPropertyExtension class] withIdentifier:@"property_i"];
    [self registerExtensionClass:[LuBlockExtension class] withIdentifier:@"block"];
    [self registerExtensionClass:[LuAddInstanceMethodExtension class] withIdentifier:@"method_create_i"];
    [self registerExtensionClass:[LuAddClassMethodExtension class] withIdentifier:@"method_create_c"];
    [self registerExtensionClass:[LuARCExtension class] withIdentifier:@"arc"];
}


-(void)registerExtensionClass:(Class)extCls withIdentifier:(NSString *)name {
         if (self.extClsRegisterMap[name] == nil) {
             self.extClsRegisterMap[name] = extCls;
         }
   
}






-(id)dispatchCommand:(JSValue *)command  fromfunction:(NSString *)funcName {
    
    NSDictionary* commandDic = [command toDictionary];
    NSString* commandId  = commandDic[@"__type"];
    LuFixBaseExtension *extension = self.extInstanceMap[commandId];
    if (extension == nil) {
        if (self.extClsRegisterMap[commandId]) {
            Class extensionKls = self.extClsRegisterMap[commandId];
            extension =  [(LuFixBaseExtension *)[extensionKls alloc]initWithJSContext:self.scriptLoader.context];
        }
    }
    NSDictionary* arguments = commandDic[@"__content"];
    SEL funSEl = NSSelectorFromString([NSString stringWithFormat:@"%@:",funcName]);
    Method method = class_getInstanceMethod(object_getClass(extension), funSEl);
    NSAssert2(method != nil, @"Extension %@ has no selector %@", NSStringFromClass(extension.class),NSStringFromSelector(funSEl));
    const char *typeDescription = method_getTypeEncoding(method);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
    const char* returnType = signature.methodReturnType;
    switch (returnType[0] == _C_CONST ? returnType[1]:returnType[0]) {
        case _C_VOID:
        {
            ((void(*)(id,SEL, id)) objc_msgSend)(extension,funSEl,arguments);
            return nil;
        }
            break;
            
        default: {
            return ((id(*)(id,SEL,id))objc_msgSend)(extension,funSEl,arguments);
        }
            break;
    }
   
}




@end
