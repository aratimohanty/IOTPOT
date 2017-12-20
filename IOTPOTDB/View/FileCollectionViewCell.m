//
//  FileCollectionViewCell.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "FileCollectionViewCell.h"

@implementation FileCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)updateCell:(NSDictionary *)dataDict {
    self.fileTitle.text = [dataDict valueForKey:@"name"];
    if ([[dataDict valueForKey:@".tag"] isEqualToString:@"folder"]) {
        self.fileImage.image =[UIImage imageNamed:@"folder.png"];
    }
    else {
        self.fileImage.image =[UIImage imageNamed:@"textfile.png"];
    }
}
@end
