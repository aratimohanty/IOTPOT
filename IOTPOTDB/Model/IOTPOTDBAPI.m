//
//  IOTPOTDBAPI.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "IOTPOTDBAPI.h"
#import "IOTPOTDBURLSessionAPI.h"

NSString *const IOTPOTDBErrorDomain = @"IOTPOTDBErrorDomain";
NSString *const IOTPOTDBErrorUserInfoKeyResponse = @"response";
NSString *const IOTPOTDBErrorUserInfoKeyDropboxError = @"dropboxError";
NSString *const IOTPOTDBErrorUserInfoKeyErrorString = @"errorString";

@implementation IOTPOTDBAPI

+ (NSURL *)tokenAuthenticationURLWithAPIKey:(NSString *const)apiKey
{
    NSURL *redirectURL = [self defaultTokenAuthenticationRedirectURLWithAPIKey:apiKey];
    return [self tokenAuthenticationURLWithAPIKey:apiKey redirectURL:redirectURL];
}

+ (NSURL *)defaultTokenAuthenticationRedirectURLWithAPIKey:(NSString *const)apiKey
{
    NSString *registeredUrlToHandle = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0];
    NSURL *redirectURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://2/token", registeredUrlToHandle]];
    return redirectURL;
}

+ (NSURL *)tokenAuthenticationURLWithAPIKey:(NSString *const)clientIdentifier redirectURL:(NSURL *const)redirectURL
{
    NSURLComponents *const components = [NSURLComponents componentsWithURL:[NSURL URLWithString:@"https://www.dropbox.com/oauth2/authorize"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
                              [NSURLQueryItem queryItemWithName:@"client_id" value:clientIdentifier],
                              [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURL.absoluteString],
                              [NSURLQueryItem queryItemWithName:@"response_type" value:@"token"],
                              [NSURLQueryItem queryItemWithName:@"disable_signup" value:@"true"]
                              ];
    return components.URL;
}

+ (NSString *)accessTokenFromURL:(NSURL *const)url withAPIKey:(NSString *const)apiKey
{
    NSURL *redirectURL = [self defaultTokenAuthenticationRedirectURLWithAPIKey:apiKey];
    return [self accessTokenFromURL:url withRedirectURL:redirectURL];
}

+ (nullable NSString *)accessTokenFromURL:(NSURL *const)url withRedirectURL:(NSURL *const)redirectURL
{
    NSString *accessToken = nil;
    if ([url.absoluteString hasPrefix:redirectURL.absoluteString]) {
        NSString *const fragment = url.fragment;
        NSURLComponents *const components = [NSURLComponents new];
        components.query = fragment;
        for (NSURLQueryItem *const item in components.queryItems) {
            if ([item.name isEqualToString:@"access_token"]) {
                accessToken = item.value;
                break;
            }
        }
    }
    return accessToken;
}

+ (void)listFolderWithPath:(NSString *const)path accessToken:(NSString *const)accessToken cursor:(NSString *const)cursor includeDeleted:(const BOOL)includeDeleted accumulatedFiles:(NSArray *const)accumulatedFiles completion:(void (^const)(NSArray<NSDictionary *> *_Nullable entries, NSString *_Nullable cursor, NSError *_Nullable error))completion
{
    NSURLRequest *const request = [self listFolderRequestWithPath:path accessToken:accessToken cursor:cursor includeDeleted:includeDeleted];
    [self performAPIRequest:request withCompletion:^(NSDictionary *parsedResponse, NSError *error) {
        if (!error) {
            NSArray *const files = [parsedResponse objectForKey:@"entries"];
            NSArray *newlyAccumulatedFiles;
            
            if ([files isKindOfClass:[NSArray class]]) {
                newlyAccumulatedFiles = accumulatedFiles.count > 0 ? [accumulatedFiles arrayByAddingObjectsFromArray:files] : files;
            } else {
                newlyAccumulatedFiles = nil;
            }
            
            id hasMoreObject = [parsedResponse objectForKey:@"has_more"];
            BOOL hasMore = [hasMoreObject respondsToSelector:@selector(boolValue)] ? [hasMoreObject boolValue] : NO;
            NSString *const cursor = [parsedResponse objectForKey:@"cursor"];
            
            if (hasMore) {
                if ([cursor isKindOfClass:[NSString class]]) {
                    // Fetch next page
                    [self listFolderWithPath:path accessToken:accessToken cursor:cursor includeDeleted:includeDeleted accumulatedFiles:newlyAccumulatedFiles completion:completion];
                } else {
                    // We can't load more without a cursor
                    completion(nil, nil, error);
                }
            } else {
                // All files fetched, finish.
                completion(newlyAccumulatedFiles, cursor, error);
            }
        } else {
            completion(nil, nil, error);
        }
    }];
}

+ (NSURLRequest *)listFolderRequestWithPath:(NSString *const)filePath accessToken:(NSString *const)accessToken cursor:(nullable NSString *const)cursor includeDeleted:(const BOOL)includeDeleted
{
    NSString *const urlPath = cursor.length > 0 ? @"/2/files/list_folder/continue" : @"/2/files/list_folder";
    NSMutableDictionary *const parameters = [NSMutableDictionary new];
    if (cursor.length > 0) {
        [parameters setObject:cursor forKey:@"cursor"];
    } else {
        [parameters setObject:[self asciiEncodeString:filePath] forKey:@"path"];
        if (includeDeleted) {
            [parameters setObject:@YES forKey:@"include_deleted"];
        }
    }
    return [self apiRequestWithPath:urlPath accessToken:accessToken parameters:parameters];
}

+ (NSString *)asciiEncodeString:(NSString *const)string
{
    NSMutableString *const result = string ? [NSMutableString new] : nil;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        const unichar character = [substring characterAtIndex:0];
        NSString *stringToAppend = nil;
        if (character > 127) {
            stringToAppend = [NSString stringWithFormat:@"\\u%04x", character];
        } else {
            stringToAppend = substring;
        }
        if (stringToAppend) {
            [result appendString:stringToAppend];
        }
    }];
    
    return result;
}

+ (NSMutableURLRequest *)apiRequestWithPath:(NSString *const)path accessToken:(NSString *const)accessToken parameters:(NSDictionary<NSString *, NSString *> *const)parameters
{
    NSMutableURLRequest *const request = [self requestWithBaseURLString:@"https://api.dropboxapi.com" path:path accessToken:accessToken];
    request.HTTPBody = [[self parameterStringForParameters:parameters] dataUsingEncoding:NSUTF8StringEncoding];
    
    if (request.HTTPBody != nil) {
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    return request;
}

+ (NSMutableURLRequest *)requestWithBaseURLString:(NSString *const)baseURLString path:(NSString *const)path accessToken:(NSString *const)accessToken
{
    NSURLComponents *const components = [[NSURLComponents alloc] initWithString:baseURLString];
    components.path = path;

    NSMutableURLRequest *const request = [[NSMutableURLRequest alloc] initWithURL:components.URL];
    request.HTTPMethod = @"POST";

    if (accessToken) {
        NSString *const authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];
        [request addValue:authorization forHTTPHeaderField:@"Authorization"];
    }

    return request;
}

+ (NSString *)parameterStringForParameters:(NSDictionary<NSString *, NSString *> *)parameters
{
    NSString *parameterString = nil;
    if (parameters.count > 0) {
        NSError *error = nil;
        NSData *const parameterData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
        if (error) {
            NSLog(@"[TJDropbox] - Error in %s: %@", __PRETTY_FUNCTION__, error);
        } else {
            parameterString = [[NSString alloc] initWithData:parameterData encoding:NSUTF8StringEncoding];

            parameterString = [parameterString stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
        }
    }
    return parameterString;
}

+ (void)performAPIRequest:(NSURLRequest *)request withCompletion:(void (^const)(NSDictionary *_Nullable parsedResponse, NSError *_Nullable error))completion
{
    NSURLSessionTask *const task = [[self session] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *parsedResult = nil;
        [self processResultJSONData:data response:response error:&error parsedResult:&parsedResult];
        completion(parsedResult, error);
    }];
    [self addTask:task];
    [task resume];
}

+ (NSURLSession *)session
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IOTPOTDBURLSessionAPI *taskDelegate = [self taskDelegate];
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:taskDelegate delegateQueue:taskDelegate.serialOperationQueue];
    });
    return session;
}

+ (IOTPOTDBURLSessionAPI *)taskDelegate
{
    static IOTPOTDBURLSessionAPI *taskDelegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskDelegate = [[IOTPOTDBURLSessionAPI alloc] init];
    });
    return taskDelegate;
}

+ (void)addTask:(NSURLSessionTask *)task
{
    static NSOperationQueue *tasksOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tasksOperationQueue = [[NSOperationQueue alloc] init];
        tasksOperationQueue.maxConcurrentOperationCount = 1;
        tasksOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    });
    [tasksOperationQueue addOperationWithBlock:^{
        [[self _tasks] addObject:task];
    }];
}

+ (NSHashTable<NSURLSessionTask *> *)_tasks
{
    static NSHashTable<NSURLSessionTask *> *hashTable = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hashTable = [NSHashTable weakObjectsHashTable];
    });
    return hashTable;
}

+ (BOOL)processResultJSONData:(NSData *const)data response:(NSURLResponse *const)response error:(inout NSError **)error parsedResult:(out NSDictionary **)parsedResult
{
    NSString *errorString = nil;
    if (data.length > 0) {
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([result isKindOfClass:[NSDictionary class]]) {
            *parsedResult = result;
        } else {
            errorString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    NSHTTPURLResponse *const httpURLResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
    const NSInteger statusCode = [httpURLResponse statusCode];
    NSDictionary *const dropboxAPIErrorDictionary = [*parsedResult objectForKey:@"error"];
    
    if (!*error) {
        if (statusCode >= 400 || dropboxAPIErrorDictionary || !*parsedResult) {
            NSMutableDictionary *const userInfo = [NSMutableDictionary new];
            if (response) {
                [userInfo setObject:response forKey:IOTPOTDBErrorUserInfoKeyResponse];
            }
            if ([dropboxAPIErrorDictionary isKindOfClass:[NSDictionary class]]) {
                [userInfo setObject:dropboxAPIErrorDictionary forKey:IOTPOTDBErrorUserInfoKeyDropboxError];
            }
            if (errorString) {
                [userInfo setObject:errorString forKey:IOTPOTDBErrorUserInfoKeyErrorString];
            }
            *error = [NSError errorWithDomain:IOTPOTDBErrorDomain code:0 userInfo:userInfo];
        }
    }
    
    return *error == nil;
}

+ (void)uploadFileAtPath:(NSString *const)localPath toPath:(NSString *const)remotePath overwriteExisting:(const BOOL)overwriteExisting accessToken:(NSString *const)accessToken progressBlock:(void (^_Nullable const)(float progress))progressBlock completion:(void (^const)(NSDictionary *_Nullable parsedResponse, NSError *_Nullable error))completion
{
    NSMutableDictionary<NSString *, id> *const parameters = [NSMutableDictionary new];
    parameters[@"path"] = [self asciiEncodeString:remotePath];
    if (overwriteExisting) {
        parameters[@"mode"] = @{@".tag": @"overwrite"};
    }
    NSURLRequest *const request = [self contentRequestWithPath:@"/2/files/upload" accessToken:accessToken parameters:parameters];
    
    NSURLSessionTask *const task = [[self session] uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:localPath]];
    
    IOTPOTDBURLSessionAPI *taskDelegate = [self taskDelegate];
    
    [taskDelegate.serialOperationQueue addOperationWithBlock:^{
        [[taskDelegate completionBlocksForDataTasks] setObject:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDictionary *parsedResult = nil;
            [self processResultJSONData:data response:response error:&error parsedResult:&parsedResult];
            
            completion(parsedResult, error);
        } forKey:task];
        if (progressBlock) {
            [[taskDelegate progressBlocksForDataTasks] setObject:progressBlock forKey:task];
        }
    }];
    
    [self addTask:task];
    [task resume];
}

+ (NSMutableURLRequest *)contentRequestWithPath:(NSString *const)path accessToken:(NSString *const)accessToken parameters:(NSDictionary<NSString *, NSString *> *const)parameters
{
    NSMutableURLRequest *const request = [self requestWithBaseURLString:@"https://content.dropboxapi.com" path:path accessToken:accessToken];
    NSString *const parameterString = [self parameterStringForParameters:parameters];
    [request setValue:parameterString forHTTPHeaderField:@"Dropbox-API-Arg"];
    return request;
}
@end
