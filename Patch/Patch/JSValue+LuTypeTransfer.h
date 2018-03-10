//
//  JSValue+LuTypeTransfer.h
//  JSPatchDemo
//
//  Created by 王宇 on 2017/6/6.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

@interface JSValue (LuTypeTransfer)

 
+(void)setArgumentWithInvocaiton:(NSInvocation *)invocation  withObject:(id)obj  atIndex:(NSInteger)index;
    

+(JSValue *)valueOfRetValueAtInvocation:(NSInvocation*)invocation inJSContext:(JSContext *)context ;



+(id)valueOfArgumentsAtInvocation:(NSInvocation*)invocation atIndex:(NSInteger)index inJSContext:(JSContext*)context;



@end




