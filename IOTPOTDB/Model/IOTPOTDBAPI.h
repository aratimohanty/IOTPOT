//
//  IOTPOTDBAPI.h
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOTPOTDBAPI : NSObject

@property (nonatomic, strong) NSString * _Nullable accessToken;

+ (NSURL *_Nonnull)tokenAuthenticationURLWithAPIKey:(NSString * _Nonnull const)apiKey;
+ (NSURL *)defaultTokenAuthenticationRedirectURLWithAPIKey:(NSString *const)apiKey;
+ (NSURL *)tokenAuthenticationURLWithAPIKey:(NSString *const)clientIdentifier redirectURL:(NSURL *const)redirectURL;
+ (NSString *)accessTokenFromURL:(NSURL *const)url withAPIKey:(NSString *const)apiKey;
+ (nullable NSString *)accessTokenFromURL:(NSURL *const)url withRedirectURL:(NSURL *const)redirectURL;
+ (void)listFolderWithPath:(NSString *const)path accessToken:(NSString *const)accessToken cursor:(NSString *const)cursor includeDeleted:(const BOOL)includeDeleted accumulatedFiles:(NSArray *const)accumulatedFiles completion:(void (^const)(NSArray<NSDictionary *> *_Nullable entries, NSString *_Nullable cursor, NSError *_Nullable error))completion;
+ (void)uploadFileAtPath:(NSString *const)localPath toPath:(NSString *const)remotePath overwriteExisting:(const BOOL)overwriteExisting accessToken:(NSString *const)accessToken progressBlock:(void (^_Nullable const)(float progress))progressBlock completion:(void (^const)(NSDictionary *_Nullable parsedResponse, NSError *_Nullable error))completion;

@end
