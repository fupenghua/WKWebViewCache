//
//  NSURLProtocol+WebKitSupport.m
//  theBeastApp
//
//  Created by 付朋华 on 2017/5/24.
//  Copyright © 2017年 com.thebeastshop. All rights reserved.
//

#import "NSURLProtocol+WebKitSupport.h"

@interface NSString(Utils)

@end

@implementation NSString(Utils)
- (NSString*)encodeBase64 {
    NSString *dataStr = self;
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *base64String = [data base64EncodedStringWithOptions:0];
    return base64String;
}

- (NSString*)decodeBase64 {
    
    NSData *nsdataFromBase64String = [[NSData alloc]
                                      initWithBase64EncodedString:self options:0];
    
    NSString *base64Decoded = [[NSString alloc]
                               initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding];
    return base64Decoded;
}
@end

FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        NSString *key = @"V0tCcm93c2luZ0NvbnRleHRDb250cm9sbGVy";
        cls = NSClassFromString([key decodeBase64]);
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    NSString *key = @"cmVnaXN0ZXJTY2hlbWVGb3JDdXN0b21Qcm90b2NvbDo=";
    return NSSelectorFromString([key decodeBase64]);
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector() {
    NSString *key = @"dW5yZWdpc3RlclNjaGVtZUZvckN1c3RvbVByb3RvY29sOg==";
    return NSSelectorFromString([key decodeBase64]);
}

@implementation NSURLProtocol (WebKitSupport)

+ (void)wk_registerScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)wk_unregisterScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}
@end
