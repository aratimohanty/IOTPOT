//
//  FileCollectionViewCell.h
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UIImageView *fileImage;
@property (strong, nonatomic) IBOutlet UILabel *fileTitle;
- (void)updateCell:(NSDictionary *)dataDict;
@end
