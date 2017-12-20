//
//  AuthViewController.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "AuthViewController.h"
#import "IOTPOTDBAPI.h"

@interface AuthViewController () <WKNavigationDelegate >

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, weak) id<IOTPOTDBAuthViewControllerDelegate> delegate;

@property (nonatomic, strong, readwrite) WKWebView *webView;

@end

@implementation AuthViewController

- (instancetype)initWithAPIKey:(NSString *const)apiKey delegate:(id<IOTPOTDBAuthViewControllerDelegate>)delegate
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.apiKey = apiKey;
        self.delegate = delegate;
        self.title = @"Login To Dropbox";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    
    NSURL *const url = [IOTPOTDBAPI tokenAuthenticationURLWithAPIKey:self.apiKey];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated){
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    NSString *const accessToken = [IOTPOTDBAPI accessTokenFromURL:navigationAction.request.URL withAPIKey:self.apiKey];
    if (accessToken.length > 0) {
        [self.delegate didAuthenticateWithAccessToken:accessToken];
    }
}

- (void)uploadImageWithAccessToken:(NSString *)accessToken completion:(void (^)(NSError *error))completionHandler  {
    NSString *filename = [NSString stringWithFormat:@"test-%lu.png", (unsigned long)CACurrentMediaTime()];
    NSString *localPath = [[NSBundle mainBundle] pathForResource: @"folder" ofType:@"png"];
    
    NSString *remotePath = [NSString stringWithFormat:@"/%@", filename];
//    [@"Testing Hello World!" writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [IOTPOTDBAPI uploadFileAtPath:localPath toPath:remotePath overwriteExisting:NO accessToken:accessToken progressBlock:nil completion:^(NSDictionary * _Nullable parsedResponse, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(error);
        });
    }];
}

@end
