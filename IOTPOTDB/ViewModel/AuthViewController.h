//
//  AuthViewController.h
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol IOTPOTDBAuthViewControllerDelegate <NSObject>

- (void)didAuthenticateWithAccessToken:(NSString *const)accessToken;
//- (void)didAuthenticateWithAccessToken:(NSString *const)accessToken;

@end

@interface AuthViewController : UIViewController

- (instancetype)initWithAPIKey:(NSString *const)apiKey delegate:(id<IOTPOTDBAuthViewControllerDelegate>)delegate;
- (void)uploadImageWithAccessToken:(NSString *)accessToken completion:(void (^)(NSError *error))completionHandler;
@end
