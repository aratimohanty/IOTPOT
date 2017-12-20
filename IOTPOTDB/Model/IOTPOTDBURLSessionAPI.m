//
//  IOTPOTDBURLSessionAPI.m
//  IOTPOTDB
//
//  Created by Soumya Ranjan Mohanty on 20/12/17.
//  Copyright © 2017 Arati. All rights reserved.
//

#import "IOTPOTDBURLSessionAPI.h"


@implementation IOTPOTDBURLSessionAPI

- (instancetype)init
{
    if (self = [super init]) {
        self.progressBlocksForDataTasks = [NSMutableDictionary new];
        self.accumulatedDataForDataTasks = [NSMutableDictionary new];
        self.completionBlocksForDataTasks = [NSMutableDictionary new];
        
        self.progressBlocksForDownloadTasks = [NSMutableDictionary new];
        self.completionBlocksForDownloadTasks = [NSMutableDictionary new];
        
        NSOperationQueue *serialOperationQueue = [[NSOperationQueue alloc] init];
        // make serial
        serialOperationQueue.maxConcurrentOperationCount = 1;
        serialOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        self.serialOperationQueue = serialOperationQueue;
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    void (^progressBlock)(float progress) = self.progressBlocksForDataTasks[task];
    
    if (progressBlock && totalBytesExpectedToSend > 0) {
        progressBlock((float)totalBytesSent / totalBytesExpectedToSend);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    void (^progressBlock)(float progress) = self.progressBlocksForDownloadTasks[task];
    
    if (progressBlock && totalBytesExpectedToWrite > 0) {
        progressBlock((float)totalBytesWritten / totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data
{
    NSMutableData *accumulatedData = self.accumulatedDataForDataTasks[task];
    if (accumulatedData) {
        [accumulatedData appendData:data];
    } else {
        self.accumulatedDataForDataTasks[task] = [data mutableCopy];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // Catches the case where the task failed.
    [self tryCompleteTask:task location:nil data:self.accumulatedDataForDataTasks[task]];
    
    [self.progressBlocksForDataTasks removeObjectForKey:task];
    [self.accumulatedDataForDataTasks removeObjectForKey:task];
    [self.completionBlocksForDataTasks removeObjectForKey:task];
    [self.progressBlocksForDownloadTasks removeObjectForKey:task];
    [self.completionBlocksForDownloadTasks removeObjectForKey:task];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location
{
    // Catches the case where the file was downloaded successfully.
    [self tryCompleteTask:task location:location data:nil];
}

- (void)tryCompleteTask:(NSURLSessionTask *const)task location:(NSURL *const)location data:(NSData *const)data
{
    void (^downloadCompletionBlock)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) = self.completionBlocksForDownloadTasks[task];
    if (downloadCompletionBlock) {
        downloadCompletionBlock(location, task.response, task.error);
        [self.completionBlocksForDownloadTasks removeObjectForKey:task];
    } else {
        void (^dataCompletionBlock)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) = self.completionBlocksForDataTasks[task];
        if (dataCompletionBlock) {
            dataCompletionBlock(self.accumulatedDataForDataTasks[task], task.response, task.error);
        }
    }
}

@end

