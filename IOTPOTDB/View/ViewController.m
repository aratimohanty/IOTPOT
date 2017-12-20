//
//  ViewController.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "ViewController.h"
#import "AuthViewController.h"
#import "HomeViewController.h"

static NSString *const kAPIKey = @"y7fronjgtvhx6qb";

@interface ViewController () <IOTPOTDBAuthViewControllerDelegate> {
    AuthViewController *authVC;
}
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic, strong) NSString *accessToken;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.accessToken = [[NSUserDefaults standardUserDefaults]valueForKey: @"ACCESSTOKEN"];
    [self setBtnTitle];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    self.title = @"IOTPOT Dropbox";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setBtnTitle {
    if (self.accessToken.length > 0) {
        [self.loginBtn setTitle:@"Logout From Dropbox" forState:UIControlStateNormal];
        [self loadHomeView];
    } else {
        [self.loginBtn setTitle:@"Login To Dropbox" forState:UIControlStateNormal];
    }
}

- (IBAction)loginBtnClicked:(id)sender {
    if (self.accessToken.length > 0) {
        self.accessToken = nil;
        [[NSUserDefaults standardUserDefaults]setValue:self.accessToken forKey: @"ACCESSTOKEN"];
        
        [self showAlertWithTitle:@"LoggedOut!" message:@"Logged Out Successfully." handler:nil];
    } else {
        authVC = [[AuthViewController alloc] initWithAPIKey:kAPIKey delegate:self];
        [self.navigationController pushViewController:authVC animated:YES];
    }
    [self setBtnTitle];
}

- (IBAction)uploadBtnClicked:(id)sender {
    if (self.accessToken.length > 0) {
        [authVC uploadImageWithAccessToken:self.accessToken completion:^(NSError *error){
            if (error) {
                [self showAlertWithTitle:@"Error!" message:error.localizedDescription handler:nil];
            } else {
                [self showAlertWithTitle:@"Success!" message:@"upload successful." handler:^(UIAlertAction * action) {
                    [self loadHomeView];
                }];
            }
        }];
    } else {
        [self showAlertWithTitle:@"Error!" message:@"You must login to upload a file" handler:nil];
    }
}

- (void)didAuthenticateWithAccessToken:(NSString *const)accessToken {
    [self.navigationController popViewControllerAnimated:YES];
    self.accessToken = accessToken;
    [[NSUserDefaults standardUserDefaults]setValue:self.accessToken forKey: @"ACCESSTOKEN"];
    [self setBtnTitle];
    NSLog(@"Authenticated with token %@", accessToken);
    [self showAlertWithTitle:@"Authenticated!" message:[NSString stringWithFormat:@"Token = %@", accessToken] handler:^(UIAlertAction * action) {
        [self loadHomeView];
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message handler:(void (^ __nullable)(UIAlertAction *action))handler {
    UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:handler]];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)loadHomeView {
    UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HomeViewController *homeVC = [mainSB instantiateViewControllerWithIdentifier:@"HomeViewController"];
    [self.navigationController pushViewController:homeVC animated:NO];
}

@end
