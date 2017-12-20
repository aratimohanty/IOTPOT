//
//  HomeViewController.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "HomeViewController.h"
#import "IOTPOTDBAPI.h"
#import "FileCollectionViewCell.h"

@interface HomeViewController ()

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic) NSMutableArray *filesArray;

@end

@implementation HomeViewController

static NSString * const reuseIdentifier = @"CustomCell";

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    self.accessToken = [[NSUserDefaults standardUserDefaults]valueForKey:@"ACCESSTOKEN"];
    [self getPublicFiles];
//    self.filesArray = [[NSMutableArray alloc]init];
}

- (void)updateData:(NSArray*)ary {
    self.filesArray = [NSMutableArray arrayWithArray:ary];
    [self.collectionView reloadData];
}

- (void)getPublicFiles {
    if (self.accessToken.length > 0) {
        NSString *searchPath = @"";
        __weak id weakSelf = self;
        [IOTPOTDBAPI listFolderWithPath:searchPath accessToken:self.accessToken cursor:nil includeDeleted:NO accumulatedFiles:nil completion:^(NSArray<NSDictionary *> * _Nullable entries, NSString * _Nullable cursor, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    NSLog(@"error %@ ", error.localizedDescription);
                } else {
//                    NSLog(@"Array %@",entries);
                    [weakSelf updateData:entries];
                }
            });
        }];
    } else {
        [self showAlertWithTitle:@"Error!" message:@"You must Login to dropbox." handler:nil];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message handler:(void (^ __nullable)(UIAlertAction *action))handler {
    UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:handler]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval = CGSizeMake(100, 120);
    return retval;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.filesArray) {
        return [self.filesArray count];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FileCollectionViewCell *cell = (FileCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell updateCell:[self.filesArray objectAtIndex:indexPath.row]];
    return cell;
}


@end
