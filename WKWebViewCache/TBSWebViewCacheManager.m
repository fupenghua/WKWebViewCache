//
//  TBSWebViewCacheManager.m
//  theBeastApp
//
//  Created by 付朋华 on 16/6/2.
//  Copyright © 2016年 com.thebeastshop. All rights reserved.
//

#import "TBSWebViewCacheManager.h"
#import "NSURLProtocol+WebKitSupport.h"

@interface TBSWebViewCacheManager()
@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) NSFileManager *fileManager;
@end


@implementation TBSWebViewCacheManager
NSArray *supportExt = nil;

//替换请求的web文件为资源包里的相对应的文件
static NSDictionary *replaceRequestFileWithLocalFile = nil;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (NSCache *)memoryCache {
    if (!_memoryCache) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = @"com.thebeastshop.thebeast.default@";
    }
    return _memoryCache;
}

- (NSString *)cacheDirect {
    if (!_cacheDirect) {
        _cacheDirect = [TBSWebViewCacheManager getCachesPath];
    }
    return _cacheDirect;
}

+ (TBSWebViewCacheManager *)share {
    static TBSWebViewCacheManager *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[TBSWebViewCacheManager alloc] init];
        share.removeMemoryCache = YES;
        share.fileManager = [NSFileManager defaultManager];
        [share addNotification];
    });
    return share;
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMemoryAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)didEnterBackground {
    if (self.removeMemoryCache) {
        [TBSWebViewCacheManager removeMemoryCache];
    }
}

+ (void)registerURLProtocol {
    for (NSString* scheme in @[@"http", @"https"]) {
        [NSURLProtocol wk_registerScheme:scheme];
    }
    [TBSWebViewCacheManager share];
    [NSURLProtocol registerClass:NSClassFromString(@"TBSWebViewCacheProtocol")];
}

+ (void)unregisterURLProtocol {
    for (NSString* scheme in @[@"http", @"https"]) {
        [NSURLProtocol wk_unregisterScheme:scheme];
    }
    [NSURLProtocol unregisterClass:NSClassFromString(@"TBSWebViewCacheProtocol")];
}

//计算单个文件大小返回值是M

+ (float)fileSizeAtPath:(NSString *)path {
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:path]){
        
        long long size = [fileManager attributesOfItemAtPath:path error:nil].fileSize;
        // 返回值是字节 B K M
        return size/1024.0/1024.0;
    }
    return 0;
}

//计算目录大小
+ (void)getWebViewCacheSizeWithBlock:(void (^)(CGFloat cacheSize))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block CGFloat size = 0;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *diskCachePath = [self getCachesPath];
        if ([fileManager fileExistsAtPath:diskCachePath]) {
            NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:diskCachePath];
            for (NSString *fileName in fileEnumerator) {
                NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                size += [attrs fileSize]/1024.0/1024.0;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            block(size);
        });
    });
}
//清理缓存文件
+ (void)clearWebViewCacheCompletion:(dispatch_block_t)completion {
    NSString *diskCachePath = [self getCachesPath];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *_fileManager=[NSFileManager defaultManager];
        if ([_fileManager fileExistsAtPath:diskCachePath]) {
            NSArray *childerFiles =[_fileManager subpathsAtPath:diskCachePath];
            for (NSString *fileName in childerFiles) {
                NSString *absolutePath = [diskCachePath stringByAppendingPathComponent:fileName];
                [_fileManager removeItemAtPath:absolutePath error:nil];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeMemoryCache];
            if (completion) {
                completion();
            }
        });
    });
}

+ (void)removeMemoryCache {
    [[self share] removeMemoryAllObjects];
}

- (void)removeMemoryAllObjects {
    [self.memoryCache removeAllObjects];
}
+ (NSString *)getCachesPath {
    // 获取diskCaches目录路径
    return [NSString stringWithFormat:@"%@/Documents/%@/", NSHomeDirectory(), @"diskCachePath"];
}

#pragma ---mark  memory cache

+ (id)dataFromMemoryCacheForKey:(NSString *)key {
    id data = [[self share].memoryCache objectForKey:key];
    return data;
}
#pragma ---mark  memory cache  end

#pragma ---mark  defaultDisk cache
+ (id)dataFromDefaultDiskCacheForPath:(NSString *)path {
    NSString *resourePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
    return [NSData dataWithContentsOfFile:resourePath];
}


#pragma ---mark  defaultDisk cache  end


+ (void)initialize {
    supportExt = @[@"jpg", @"jpeg", @"png", @"gif", @"css", @"js",@"html",@"webp"];
}

+ (NSString *)getExtFromUrl:(NSString *)absoluteUrl {
    NSString *pathString = absoluteUrl;
    NSString *ext = [pathString lastPathComponent];
    ext = [ext lowercaseString];
    NSRange rang = [ext rangeOfString:@"?"];
    if (rang.location != NSNotFound)
    {
        ext = [ext substringToIndex:rang.location];
    }
    rang = [ext rangeOfString:@"!"];
    if (rang.location != NSNotFound)
    {
        ext = [ext substringToIndex:rang.location];
    }
    ext = [ext pathExtension];
    return ext;
}
+ (NSData *)dataForURL:(NSString *)url {
    NSString *cacheDirect = [self webCacheDirectPath];
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", cacheDirect, url];
    
    NSData *cacheData = [NSData dataWithContentsOfFile:cachePath];
    
    return cacheData;
}

+ (NSString *)webCacheDirectPath {
    NSString *direct = [self share].cacheDirect;
    BOOL isDirect = NO;
    NSError *err = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:direct isDirectory:&isDirect] || !isDirect)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:direct withIntermediateDirectories:NO attributes:nil error:&err];
    }
    return direct;
}

+ (void)storeData:(NSData *)data forURL:(NSString *)url completion:(dispatch_block_t)completion {
    NSString *ext = [self getExtFromUrl:url];
    if (![self hasDataForURL:url] && [supportExt containsObject:ext]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [[self share].memoryCache setObject:data forKey:url];//同时 存入diskCache， memory cache
                NSString *cacheDirect = [self webCacheDirectPath];
                NSString *cachePath = [NSString stringWithFormat:@"%@%@", cacheDirect, url];
                if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
                    [data writeToFile:cachePath atomically:YES];
                    if (completion) {
                        completion();
                    }
                }
            }
        });
    }
}

+ (BOOL)hasDataForURL:(NSString *)url
{
    
    NSString *cacheDirect = [self webCacheDirectPath];
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", cacheDirect, url];
    
    BOOL isDirect = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDirect] && !isDirect)
    {
        return YES;
    }
    return NO;
}


+ (NSString *)loadLocalWebSourcePathWithUrl:(NSString *)key
{
    if (replaceRequestFileWithLocalFile && [replaceRequestFileWithLocalFile count])
    {
        if ([replaceRequestFileWithLocalFile.allKeys containsObject:key])
        {
            NSString *localWebSourceFileName = replaceRequestFileWithLocalFile[key];
            NSString *path = [NSString stringWithFormat:@"%@/Documents/%@/%@", NSHomeDirectory(), @"diskCachePath", localWebSourceFileName];
            return path;
        }
    }
    return nil;
}

+ (void)saveMemoryData:(NSData *)data keyName:(NSString *)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self share].memoryCache setObject:data forKey:key];
    });
}

+ (NSData *)getCacheDataWithPathString:(NSString *)pathString {
    NSData *data = nil;
    if ([self dataFromMemoryCacheForKey:pathString]) {
        data = [self dataFromMemoryCacheForKey:pathString];
    } else {
        data = [self diskCacheDataWithPathString:pathString];
    }
    return data;
}

+ (NSData *)diskCacheDataWithPathString:(NSString *)pathString {
    NSData *data= nil;
    if ([self hasDataForURL:pathString]) {//有缓存直接加载缓存
        data = [self dataForURL:pathString];
        [self saveMemoryData:data keyName:pathString];//diskCache 存在， memory cache 不存在  则加入memory cache中
    } else {
        data = [self dataFromDefaultDiskCacheForPath:pathString];
        if (data) {
            [self saveMemoryData:data keyName:pathString];//defaultDiskCache 存在,则加入memory cache中
        }
    }
    return data;
}


@end


