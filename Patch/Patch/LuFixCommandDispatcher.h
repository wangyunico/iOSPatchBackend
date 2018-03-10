//
//  LuFixCommandDispatcher.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/12.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuScriptLoader.h"

@interface LuFixCommandDispatcher : NSObject



-(id)initWithLuScriptLoader:(LuScriptLoader *)scriptLoader;




/**
 *   定义class
 *
 *  @param extCls className
 *  @param name   名字
 */
-(void)registerExtensionClass:(Class)extCls withIdentifier:(NSString *)name;


/**
 *   根据command 解析出type，根据type 将content 发送到Extension中
 *
 *  @param command   指令
 *  @param funcName 表示 declare 还是 eval 从而反射出sel,进行调用
 */
-(id)dispatchCommand:(JSValue *)command  fromfunction:(NSString *)funcName;

@end
