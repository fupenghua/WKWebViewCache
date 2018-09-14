//
//  TBSWebViewCacheProtocol.m
//  theBeastApp
//
//  Created by 付朋华 on 2018/9/13.
//  Copyright © 2018年 com.thebeastshop. All rights reserved.
//

#import "TBSWebViewCacheProtocol.h"
#import "TBSWebViewCacheManager.h"

@interface TBSWebViewCacheProtocol()<NSURLSessionDelegate>
@property (strong, nonatomic) NSMutableData *responseData;
@property (nonnull,strong) NSURLSessionDataTask *task;
@end
static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@implementation TBSWebViewCacheProtocol

- (NSMutableData *)responseData {
    if (!_responseData) {
        _responseData = [[NSMutableData alloc] init];
    }
    return _responseData;
}
#pragma ---mark NSCacheProtocol method

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    //看看是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    NSURL *url = request.URL;
    if (![self containWebviewCacheDomains:url] && ![self containInUrlWhitelist:request.URL]) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    WebviewResetURLRequestHandler resetHandler = [TBSWebViewCacheManager share].webviewResetURLRequestHandler;
    if (resetHandler) {
        return resetHandler(request);
    }
    return request;
}

- (void)startLoading {
    if ([TBSWebViewCacheProtocol containWebviewCacheDomains:self.request.URL]) {
        NSString *pathString = [self pathString];
        NSData *data = [TBSWebViewCacheManager getCacheDataWithPathString:pathString];
        if (data) {
            [self loadData:data];
            return;
        }
    }
    [self loadRequest];
}
- (void)stopLoading {
    [self cancelConnection];
}

+ (BOOL)containWebviewCacheDomains:(NSURL *)url {
    WebviewCacheDomainsHandler cacheHandler = [TBSWebViewCacheManager share].webviewCacheDomainsHandler;
    BOOL can = NO;
    if (cacheHandler) {
        can = cacheHandler(url);
    }
    return can;
}

+ (BOOL)containInUrlWhitelist:(NSURL *)url {
    WebviewDomainWhitelistHandler whiteListHandler = [TBSWebViewCacheManager share].webviewDomainWhitelistHandler;
    BOOL can = YES;
    if (whiteListHandler) {
        can = whiteListHandler(url);
    }
    return can;
}

- (void)loadData:(NSData *)data {
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL]
                                                        MIMEType:@"*/*"
                                           expectedContentLength:data.length
                                                textEncodingName:nil];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)loadRequest {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    mutableReqeust.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.task = [session dataTaskWithRequest:mutableReqeust];
    [self.task resume];
}

- (void)cancelConnection {
    self.responseData = nil;
    if (self.task){
        [self.task cancel];
    }
}

- (NSString *)pathString {
    NSString *DNSIp = self.request.URL.host;
    NSString *scheme = [NSString stringWithFormat:@"%@://%@",self.request.URL.scheme,DNSIp];
    NSString *domainStr = TBSWebViewCacheManager.share.getNewDomain(scheme);
    
    NSString *domain = self.request.URL.host;
    NSString *pathName = [self.request.URL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *strRequest = [NSString stringWithFormat:@"%@%@",domain,pathName];//domain +pathName  组成key
    NSString *pathString = [strRequest stringByReplacingOccurrencesOfString:@"/" withString:@"~"];
    if (domainStr)
        pathString = [pathString stringByReplacingOccurrencesOfString:DNSIp withString:domainStr];
    return pathString;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self cacheData];
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)cacheData {
    if ([TBSWebViewCacheProtocol containWebviewCacheDomains:self.request.URL]) {
        NSString *pathString = [self pathString];
        [TBSWebViewCacheManager storeData:self.responseData forURL:pathString completion:^{
            self.responseData = nil;
        }];
    }
}
@end
