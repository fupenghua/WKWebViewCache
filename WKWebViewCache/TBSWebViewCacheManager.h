//
//  TBSWebViewCacheManager.h
//  theBeastApp
//
//  Created by 付朋华 on 16/6/2.
//  Copyright © 2016年 com.thebeastshop. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSMutableURLRequest *(^WebviewResetURLRequestHandler)(NSURLRequest *request);
typedef BOOL(^WebviewVerifiedDomainsHandler)(NSURL *url);
typedef BOOL(^WebviewDomainWhitelistHandler)(NSURL *url);
typedef BOOL(^WebviewCacheDomainsHandler)(NSURL *url);
@interface TBSWebViewCacheManager : NSObject
/**
 缓存文件夹路径  可自定义  也可不设置
 */
@property (nonatomic, strong) NSString *cacheDirect;

/**
 webView load request， you can add headers for the request or change request domain.
 */
@property (nonatomic, copy) WebviewResetURLRequestHandler webviewResetURLRequestHandler;

/**
 通过request判断domain是否在域名白名单中，返回NO，则会直接屏蔽 不实现默认全部通过  如果不是实现可能会导致第三方的一些请求或者网页加载失败
 */
@property (nonatomic, copy) WebviewDomainWhitelistHandler webviewDomainWhitelistHandler;

/**
 通过request的domain处理是否进行缓存逻辑，返回YES 会加入离线缓存 该属性不实现默认都加入缓存
 */
@property (nonatomic, copy) WebviewCacheDomainsHandler webviewCacheDomainsHandler;  //

@property (nonatomic, readonly) NSCache *memoryCache;

/**
 程序进入后台时是否清除内存  default YES
 */
@property (nonatomic, assign) BOOL removeMemoryCache;

+ (TBSWebViewCacheManager *)share;

/**
 APP启动时候先注册urlProtocol
 */
+ (void)registerURLProtocol;

/**
 清除内存
 */
+ (void)removeMemoryCache;

/**
 通过path读取缓存

 @param pathString path
 @return 缓存
 */
+ (NSData *)getCacheDataWithPathString:(NSString *)pathString;

/**
 存储数据

 @param data data
 @param url 存储名称
 @param completion 完成回调
 */
+ (void)storeData:(NSData *)data forURL:(NSString *)url completion:(dispatch_block_t)completion;
+ (void)getWebViewCacheSizeWithBlock:(void (^)(CGFloat cacheSize))block;
+ (void)clearWebViewCacheCompletion:(dispatch_block_t)completion;
@end

