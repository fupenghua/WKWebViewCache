//
//  NSURLProtocol+WebKitSupport.h
//  theBeastApp
//
//  Created by 付朋华 on 2017/5/24.
//  Copyright © 2017年 com.thebeastshop. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (WebKitSupport)
+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString *)scheme;
@end
