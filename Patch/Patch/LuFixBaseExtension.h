//
//  LuFixBaseExtension.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuScriptLoader.h"
#import "LuFixCommandDispatcher.h"

// 声明用于存放JSMethod的Dictioanry 根据当前类对象和方法能够找到该对象

extern  NSMutableDictionary* _LUFixJSMethods;

@interface LuFixBaseExtension : NSObject

@property (nonatomic,weak) JSContext *context;




-(id)initWithJSContext:(JSContext *)context;


 void __LUFIX_CALLEE__(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation);

void initLUFixJSMethods(Class cls);

SEL lufix_aliasForSelector(SEL selector);

@end
