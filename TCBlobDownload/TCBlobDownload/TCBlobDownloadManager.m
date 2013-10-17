//
//  TCBlobDownloadManager.m
//
//  Created by Thibault Charbonnier on 16/04/13.
//  Copyright (c) 2013 Thibault Charbonnier. All rights reserved.
//

#import "TCBlobDownloadManager.h"

@interface TCBlobDownloadManager ()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation TCBlobDownloadManager
@dynamic downloadCount;


#pragma mark - Init


- (id)init
{
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        //_defaultDownloadPath = [paths objectAtIndex:0];
        _defaultDownloadPath = [NSString stringWithString:NSTemporaryDirectory()];
    }
    return self;
}

+ (id)sharedDownloadManager
{
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    
    return sharedManager;
}


#pragma mark - Utilities


- (void)setDefaultDownloadPath:(NSString *)pathToDL
{
    if ([TCBlobDownload createPathFromPath:pathToDL]) {
        _defaultDownloadPath = pathToDL;
    }
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrent
{
    [self.operationQueue setMaxConcurrentOperationCount:maxConcurrent];
}


#pragma mark - Getters


- (NSUInteger)downloadCount
{
    return [_operationQueue operationCount];
}


#pragma mark - TCBlobDownloads Management


- (TCBlobDownload *)startDownloadWithURL:(NSURL *)url
                  customPath:(NSString *)customPathOrNil
                    delegate:(id<TCBlobDownloadDelegate>)delegateOrNil
{
    NSString *downloadPath = self.defaultDownloadPath;
    if (customPathOrNil != nil && [TCBlobDownload createPathFromPath:customPathOrNil]) {
        downloadPath = customPathOrNil;
    }
    
    TCBlobDownload *downloader = [[TCBlobDownload alloc] initWithURL:url
                                                        downloadPath:downloadPath
                                                         delegate:delegateOrNil];
    [_operationQueue addOperation:downloader];
    
    return downloader;
}

- (TCBlobDownload *)startDownloadWithURL:(NSURL *)url
                  customPath:(NSString *)customPathOrNil
               firstResponse:(FirstResponseBlock)firstResponseBlock
                    progress:(ProgressBlock)progressBlock
                       error:(ErrorBlock)errorBlock
                    complete:(CompleteBlock)completeBlock
{
    NSString *downloadPath = self.defaultDownloadPath;
    if (nil != customPathOrNil && [TCBlobDownload createPathFromPath:customPathOrNil]) {
        downloadPath = customPathOrNil;
    }
    
    TCBlobDownload *downloader = [[TCBlobDownload alloc] initWithURL:url
                                                        downloadPath:downloadPath
                                                       firstResponse:firstResponseBlock
                                                            progress:progressBlock
                                                               error:errorBlock
                                                            complete:completeBlock];
    [self.operationQueue addOperation:downloader];
    
    return downloader;
}

- (void)startDownload:(TCBlobDownload *)blobDownload
{
    [self.operationQueue addOperation:blobDownload];
}

- (void)cancelAllDownloadsAndRemoveFiles:(BOOL)remove
{
    for (TCBlobDownload *blob in [self.operationQueue operations]) {
        [blob cancelDownloadAndRemoveFile:remove];
    }
    TCLog(@"Cancelled all downloads.");
}

@end
