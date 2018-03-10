//
//  LuBlockWrapper.h
//  JSPatchDemo
//
//  Created by Jaime on 2017/7/18.
//  Copyright © 2017年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface LuBlockWrapper : NSObject
- (void *)blockPointer;
- (id)initWithTypeString:(NSString *)typeString callbackFunction:(JSValue *)jsFunction inContext:(JSContext *)context;
@end
