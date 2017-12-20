//
//  IOTPOTDBURLSessionAPI.h
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOTPOTDBURLSessionAPI : NSObject <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSMutableDictionary *progressBlocksForDataTasks;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionTask *, NSMutableData *> *accumulatedDataForDataTasks;
@property (nonatomic, strong) NSMutableDictionary *completionBlocksForDataTasks;

@property (nonatomic, strong) NSMutableDictionary *progressBlocksForDownloadTasks;
@property (nonatomic, strong) NSMutableDictionary *completionBlocksForDownloadTasks;

@property (nonatomic, strong) NSOperationQueue *serialOperationQueue;

@end
