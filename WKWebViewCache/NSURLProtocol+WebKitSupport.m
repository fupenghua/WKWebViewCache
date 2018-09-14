//
//  NSURLProtocol+WebKitSupport.m
//  theBeastApp
//
//  Created by 付朋华 on 2017/5/24.
//  Copyright © 2017年 com.thebeastshop. All rights reserved.
//

#import "NSURLProtocol+WebKitSupport.h"

FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        NSString *key = @"V0tCcm93c2luZ0NvbnRleHRDb250cm9sbGVy";
        cls = NSClassFromString([key decodeBase64String]);
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    NSString *key = @"cmVnaXN0ZXJTY2hlbWVGb3JDdXN0b21Qcm90b2NvbDo=";
    return NSSelectorFromString([key decodeBase64String]);
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
@end
