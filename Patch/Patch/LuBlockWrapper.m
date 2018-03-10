//
//  LuBlockWrapper.m
//  JSPatchDemo
//
//  Created by Jaime on 2017/7/18.
//  Copyright © 2017年 bang. All rights reserved.
//

#import "LuBlockWrapper.h"
#import "ffi.h"
#import <objc/runtime.h>

enum {
    BLOCK_DEALLOCATING =      (0x0001),
    BLOCK_REFCOUNT_MASK =     (0xfffe),
    BLOCK_NEEDS_FREE =        (1 << 24),
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26),
    BLOCK_IS_GC =             (1 << 27),
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_USE_STRET =         (1 << 29),
    BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

struct LPSimulateBlock {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct LPSimulateBlockDescriptor *descriptor;
    void *retainWrapper;
};

struct LPSimulateBlockDescriptor {
    //Block_descriptor_1
    struct {
        unsigned long int reserved;
        unsigned long int size;
    };
    //Block_descriptor_2
    struct {
        // requires BLOCK_HAS_COPY_DISPOSE
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
    };
    struct {
        // requires BLOCK_HAS_SIGNATURE
        const char *signature;
        const char *layout;
    };
};

static const NSDictionary *_registeredStruct;
static  NSPointerArray *_structTypes;
static  NSMutableArray *_structNames;


static void __lu_block_dispose(struct LPSimulateBlock* src){
    
    //LuBlockWrapper *wra =  (__bridge_transfer LuBlockWrapper*)src ->retainWrapper;
    //_Block_object_dispose((src ->retainWrapper), 3);
    CFRelease(src -> retainWrapper);

}

static void __lu_block_copy(struct LPSimulateBlock*dst, struct LPSimulateBlock*src){
    //_Block_object_assign((void*)dst -> retainWrapper, (void*)src -> retainWrapper, 3);
}

@interface LuBlockWrapper() {
    NSString *_types;
    
    ffi_cif *_cifPtr;
    ffi_type **_args;
    ffi_closure *_closure;
    //void *_blockPtr;
    struct LPSimulateBlockDescriptor *_descriptor;
}

@property (nonatomic,strong) NSMutableArray *argumentTypes;
@property (nonatomic,strong) NSString *returnType;
@property (nonatomic,strong) JSValue *jsFunction;
@property (nonatomic,strong) JSContext *context;

@end

@implementation LuBlockWrapper

+ (void)load {
    [LuBlockWrapper addCustomStruct];
}

- (id)initWithTypeString:(NSString *)typeEncoding callbackFunction:(JSValue *)jsFunction inContext:(JSContext *)context
{
    self = [super init];
    if(self) {
        self.jsFunction = jsFunction;
        self.context = context;
        NSArray *types = [typeEncoding componentsSeparatedByString:@","];
        self.returnType = [types firstObject];
        self.argumentTypes = [NSMutableArray arrayWithObject:@"@?"];
        [self.argumentTypes addObjectsFromArray:[types subarrayWithRange:NSMakeRange(1, types.count-1)]];
        [self _parseTypes:typeEncoding];
    }
    return self;
}

//获取类型编码+类型长度->block描述符
- (void)_parseTypes:(NSString*)typeEncoding {
    NSMutableString *encodeStr = [[NSMutableString alloc] init];
    NSArray *typeArr = [typeEncoding componentsSeparatedByString:@","];
    
    for (int i=0; i<typeArr.count; i++) {
        NSString *encode = typeArr[i];
        [encodeStr appendString:encode];
        int length = [LuBlockWrapper typeLengthWithTypeEncode:encode];
        [encodeStr appendString:[NSString stringWithFormat:@"%d", length]];
        
        if (i==0) {
            [encodeStr appendString:@"@?0"];
        }
    }
    _types = encodeStr;
}


//获取为任意JS func 生成的block指针
- (void*)blockPointer {
    void *blockImp = NULL;
    _cifPtr = malloc(sizeof(ffi_cif));  //函数原型
    
    ffi_type *returnType = [LuBlockWrapper ffiTypeWithEncodingChar:[_returnType UTF8String]];
    NSUInteger argumentCount = self.argumentTypes.count;
    _args = malloc(sizeof(ffi_type *) *argumentCount);
    for (int i=0; i<argumentCount; i++) {
        ffi_type *currentType = [LuBlockWrapper ffiTypeWithEncodingChar:[self.argumentTypes[i] UTF8String]];
        _args[i] = currentType;
    }
    
    //CFTypeRef ref = (__bridge_retained void*)self;  CF对象拥有对象所有权,保证函数实体执行前不释放
    _closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&blockImp);
    
    struct LPSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct LPSimulateBlock),
        (void(*)(void*, const void *))__lu_block_copy,
        (void(*)(const void *))__lu_block_dispose,
        [_types cStringUsingEncoding:NSUTF8StringEncoding],
        NULL
    };
    
    _descriptor = malloc(sizeof(struct LPSimulateBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct LPSimulateBlockDescriptor));
      
    struct LPSimulateBlock simulateBlock = {
        &_NSConcreteStackBlock,
        (BLOCK_HAS_SIGNATURE|BLOCK_HAS_COPY_DISPOSE), 0,
        blockImp,
        _descriptor,
        (__bridge_retained void *)self
    };
    
   void* blockPtr = malloc(sizeof(struct LPSimulateBlock));
    memcpy(blockPtr, &simulateBlock, sizeof(struct LPSimulateBlock));
    if(ffi_prep_cif(_cifPtr, FFI_DEFAULT_ABI, (unsigned int)argumentCount, returnType, _args) == FFI_OK) {
        if (ffi_prep_closure_loc(_closure, _cifPtr, LPBlockInterpreter, blockPtr, blockImp) != FFI_OK) {
            NSAssert(NO, @"generate block error");
        }
    }
    return blockPtr;
}

//释放ffi相关
- (void)dealloc
{
    ffi_closure_free(_closure);
    free(_args);
    free(_cifPtr);
    //free(_blockPtr);
    free(_descriptor);
    return;
}


//函数实体
void LPBlockInterpreter(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    struct LPSimulateBlock * block = userdata;
    LuBlockWrapper *extension = (__bridge LuBlockWrapper*) block -> retainWrapper;
    //LuBlockWrapper *extension = (__bridge_transfer LuBlockWrapper*)userdata; //临时变量OC 对象拥有对象所有权，函数执行完毕退栈时清除引用
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (int i = 1; i < extension.argumentTypes.count; i ++) {
        id param;
        void *argumentPtr = args[i];
        const char *typeEncoding = [extension.argumentTypes[i] UTF8String];
        switch (typeEncoding[0]) {
                
#define LP_BLOCK_PARAM_CASE(_typeString, _type, _selector) \
case _typeString: {                              \
_type returnValue = *(_type *)argumentPtr;                     \
param = [NSNumber _selector:returnValue];\
break; \
}
                LP_BLOCK_PARAM_CASE('c', char, numberWithChar)
                LP_BLOCK_PARAM_CASE('C', unsigned char, numberWithUnsignedChar)
                LP_BLOCK_PARAM_CASE('s', short, numberWithShort)
                LP_BLOCK_PARAM_CASE('S', unsigned short, numberWithUnsignedShort)
                LP_BLOCK_PARAM_CASE('i', int, numberWithInt)
                LP_BLOCK_PARAM_CASE('I', unsigned int, numberWithUnsignedInt)
                LP_BLOCK_PARAM_CASE('l', long, numberWithLong)
                LP_BLOCK_PARAM_CASE('L', unsigned long, numberWithUnsignedLong)
                LP_BLOCK_PARAM_CASE('q', long long, numberWithLongLong)
                LP_BLOCK_PARAM_CASE('Q', unsigned long long, numberWithUnsignedLongLong)
                LP_BLOCK_PARAM_CASE('f', float, numberWithFloat)
                LP_BLOCK_PARAM_CASE('d', double, numberWithDouble)
                LP_BLOCK_PARAM_CASE('B', BOOL, numberWithBool)
            case '@': {
                param = (__bridge id)(*(void**)argumentPtr);
                break;
            }
            case _C_STRUCT_B: {
                
                NSString *typeString = [NSString stringWithUTF8String:typeEncoding];
#define LU_JSVALUE_ARG_STRUCT(_type, _methodName) \
if([typeString rangeOfString:@#_type].location != NSNotFound){\
_type arg = *((_type*)argumentPtr); \
param = [JSValue _methodName: arg inContext: extension.context];\
break;\
}
                LU_JSVALUE_ARG_STRUCT(CGRect, valueWithRect)
                LU_JSVALUE_ARG_STRUCT(CGPoint, valueWithPoint)
                LU_JSVALUE_ARG_STRUCT(CGSize, valueWithSize)
                LU_JSVALUE_ARG_STRUCT(NSRange, valueWithRange)
                //todo: 支持其他struct 类型
                break;
            }
        }
        [params addObject:param];
    }
    
    JSValue *jsResult = [extension.jsFunction callWithArguments:params];
    
    switch ([extension.returnType UTF8String][0]) {
            
#define LP_BLOCK_RET_CASE(_typeString, _type, _selector) \
case _typeString: {                              \
_type *retPtr = ret; \
*retPtr = [((NSNumber *)[jsResult toObject]) _selector];   \
break; \
}
            
            LP_BLOCK_RET_CASE('c', char, charValue)
            LP_BLOCK_RET_CASE('C', unsigned char, unsignedCharValue)
            LP_BLOCK_RET_CASE('s', short, shortValue)
            LP_BLOCK_RET_CASE('S', unsigned short, unsignedShortValue)
            LP_BLOCK_RET_CASE('i', int, intValue)
            LP_BLOCK_RET_CASE('I', unsigned int, unsignedIntValue)
            LP_BLOCK_RET_CASE('l', long, longValue)
            LP_BLOCK_RET_CASE('L', unsigned long, unsignedLongValue)
            LP_BLOCK_RET_CASE('q', long long, longLongValue)
            LP_BLOCK_RET_CASE('Q', unsigned long long, unsignedLongLongValue)
            LP_BLOCK_RET_CASE('f', float, floatValue)
            LP_BLOCK_RET_CASE('d', double, doubleValue)
            LP_BLOCK_RET_CASE('B', BOOL, boolValue)
            
        case '@':
        case '#': {
            id retObj = transferJSValue(jsResult);
            void **retPtrPtr = ret;
            *retPtrPtr = (__bridge void *)retObj;
            break;
        }
        case '^': {
            //返回(void *)/(id *)时 非对象处理
            break;
        }
    }
}



#pragma mark - class methods

+ (ffi_type *)ffiTypeWithEncodingChar:(const char *)c
{
    switch (c[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'F':
#if CGFLOAT_IS_DOUBLE
            return &ffi_type_double;
#else
            return &ffi_type_float;
#endif
        case 'B':
            return &ffi_type_uint8;
        case '^':
            return &ffi_type_pointer;
        case '@':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case '{':
        {
            NSString *typeStr = [NSString stringWithCString:c encoding:NSASCIIStringEncoding];
            NSRange range = [typeStr rangeOfString:@"}" options:NSBackwardsSearch];
            NSUInteger end = range.location;
            if (end != NSNotFound) {
                NSString *structName = [typeStr substringWithRange:NSMakeRange(1, end - 1)];
                ffi_type *type = [LuBlockWrapper getStructType:structName];
                return type;
            }
        }
    }
    return NULL;
}

static NSMutableDictionary *_typeLengthDict;

+ (int)typeLengthWithTypeEncode:(NSString *)typeEncode
{
    if (!typeEncode) return 0;
    if (!_typeLengthDict) {
        _typeLengthDict = [[NSMutableDictionary alloc] init];
        
        
#define LP_DEFINE_TYPE_LENGTH(_type,encode) \
[_typeLengthDict setObject:@(sizeof(_type)) forKey:encode];\

        LP_DEFINE_TYPE_LENGTH(id,@"@");
        LP_DEFINE_TYPE_LENGTH(BOOL,@"B");
        LP_DEFINE_TYPE_LENGTH(int,@"i");
        LP_DEFINE_TYPE_LENGTH(void,@"v");
        LP_DEFINE_TYPE_LENGTH(char,@"c");
        LP_DEFINE_TYPE_LENGTH(short,@"s");
        LP_DEFINE_TYPE_LENGTH(unsigned short,@"S");
        LP_DEFINE_TYPE_LENGTH(unsigned int,@"I");
        LP_DEFINE_TYPE_LENGTH(long,@"q");
        LP_DEFINE_TYPE_LENGTH(unsigned long,@"Q");
        LP_DEFINE_TYPE_LENGTH(long long,@"q");
        LP_DEFINE_TYPE_LENGTH(unsigned long long,@"Q");
        LP_DEFINE_TYPE_LENGTH(float,@"f");
        LP_DEFINE_TYPE_LENGTH(double,@"d");
        LP_DEFINE_TYPE_LENGTH(bool,@"B");
        LP_DEFINE_TYPE_LENGTH(size_t,@"Q");
        LP_DEFINE_TYPE_LENGTH(CGFloat,@"d");
        LP_DEFINE_TYPE_LENGTH(CGSize,@"{CGSize=dd}");
        LP_DEFINE_TYPE_LENGTH(CGRect,@"{CGRect={CGPoint=dd}{CGSize=dd}}");
        LP_DEFINE_TYPE_LENGTH(CGPoint,@"{CGPoint=dd}");
        LP_DEFINE_TYPE_LENGTH(CGVector,@"{CGVector=dd}");
        LP_DEFINE_TYPE_LENGTH(NSRange,@"{_NSRange=QQ}");
        LP_DEFINE_TYPE_LENGTH(NSInteger,@"q");
        LP_DEFINE_TYPE_LENGTH(Class,@"#");
        LP_DEFINE_TYPE_LENGTH(SEL,@":");
        LP_DEFINE_TYPE_LENGTH(void*,@"^v");
        LP_DEFINE_TYPE_LENGTH(void *,@"^v");
        LP_DEFINE_TYPE_LENGTH(id *,@"^@");
        LP_DEFINE_TYPE_LENGTH(id *,@"@?");
    }
    return [_typeLengthDict[typeEncode] intValue];
}

static id transferJSValue(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return nil;
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:transferJSValue(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:transferJSValue(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}

+ (const NSDictionary *)registeredStruct
{
    return _registeredStruct;
}


+ (void)addCustomStruct {
    _structTypes = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsOpaqueMemory];
    _structNames = [[NSMutableArray alloc]init];
    
    [LuBlockWrapper addStructDefine:@{@"types": @"d,d",@"keys": @[@"width",@"height"]} structName:@"CGSize=dd"];
    [LuBlockWrapper addStructDefine:@{@"types": @"d,d",@"keys": @[@"x",@"y"]} structName:@"CGPoint=dd"];
    [LuBlockWrapper addStructDefine:@{@"types": @"d,d",@"keys": @[@"dx",@"dy"]} structName:@"CGVector=dd"];
    [LuBlockWrapper addStructDefine:@{@"types": @"Q,Q",@"keys": @[@"location",@"length"]} structName:@"_NSRange=QQ"];
    [LuBlockWrapper addStructDefine:@{@"types": @"{CGPoint=dd},{CGSize=dd}",@"keys": @[@"CGPoint",@"CGSize"]} structName:@"CGRect={CGPoint=dd}{CGSize=dd}"];
}

+ (void)addStructDefine:(NSDictionary*)define structName:(NSString *)name {
    [_structNames addObject:name];
    [_structTypes addPointer:[LuBlockWrapper createStructType:define]];
}

+ (ffi_type *)createStructType:(NSDictionary*)structDefine {
    ffi_type *type = malloc(sizeof(ffi_type));
    type->alignment = 0;
    type->size = 0;
    type->type = FFI_TYPE_STRUCT;
    NSUInteger subTypeCount = [structDefine[@"keys"] count];
    NSArray *subTypes = [structDefine[@"types"] componentsSeparatedByString:@","];
    
    ffi_type **sub_types = malloc(sizeof(ffi_type *) * (subTypeCount + 1));
    for (NSUInteger i=0; i<subTypeCount; i++) {
        sub_types[i] = [LuBlockWrapper ffiTypeWithEncodingChar:[subTypes[i] cStringUsingEncoding:NSASCIIStringEncoding]];
        type->size += sub_types[i]->size;
    }
    sub_types[subTypeCount] = NULL;
    type->elements = sub_types;
    return type;
}


+ (ffi_type *)getStructType:(NSString*)structName{
    return [_structTypes pointerAtIndex:[_structNames indexOfObject:structName]];
}

@end
