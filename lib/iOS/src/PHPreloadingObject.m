//
//  PHPreloadingObject.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/23/15.
//
//

#import "PHPreloadingObject.h"
#import "PHPreloader.h"
#import "PHConstants.h"

NSString * const PHDidStartPreloadingNotification = @"itemStartedPreloading";
NSString * const PHDidFinishPreloadingNotification = @"itemFinishedDownloading";
NSString * const PHDidFailToPreloadNotification = @"itemFailedToDownload";
NSString * const PHDidReceiveDataNotification = @"itemReceivedData";

@interface PHPreloadingObject() {
    NSMutableData *_receivedData;
    NSURLConnection *_connection;
    NSInteger _downloadSize;
    NSString *_downloadDirectoy;
}

@end

@implementation PHPreloadingObject

- (id)initWithBeaconManager:(PHBeaconManager *)beaconManager url:(NSURL *)url creativeId:(NSInteger)creativeId {
    self = [super init];
    if (self){
        self.cacheObject = [[PHCacheObject alloc] initWithURLString:url creativeId:creativeId];
        self.downloading = NO;
        self.beaconManager = beaconManager;
        _downloadDirectoy = [[PHPreloader getDownloadDirectory] copy];
    }
    return self;
}

- (void)start {
    self.downloading = YES;
    _receivedData = [[NSMutableData alloc] initWithLength:0];
    NSURLRequest *request = [NSURLRequest requestWithURL:self.cacheObject.url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:60.0];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
}

- (void)stop {
    if (_connection) {
        [_connection cancel];
        [self.beaconManager pingBeaconForEvent:PHDidCancelPreload withData:nil];
    }
}

- (void)save {
    // save the file to disk
    NSString *fileName = [_downloadDirectoy stringByAppendingFormat:@"/%@", self.cacheObject.fileName];
    [_receivedData writeToFile:fileName atomically:YES];
    
    NSMutableArray *savedFiles = [PHPreloader newSavedFilesArray];
    if (savedFiles == nil) {
        savedFiles = [[NSMutableArray alloc] init];
    }
  
    [savedFiles addObject:self.cacheObject];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:savedFiles] forKey:PH_CACHE_USER_DEFAULT_KEY];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    PH_DEBUG(@"Download of %@ started", [self.cacheObject.url absoluteString]);
    [_receivedData setLength:0];
    _downloadSize = response.expectedContentLength;
    [self.beaconManager pingBeaconForEvent:PHDidStartPreloading withData:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDidStartPreloadingNotification object:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_receivedData appendData:data];
    self.percentLoaded = (((float)_receivedData.length / (float)_downloadSize) * 100);
    PH_DEBUG(@"%lu of %li received (%f%%)", (unsigned long)_receivedData.length, (long)_downloadSize, self.percentLoaded);
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDidReceiveDataNotification object:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    PH_DEBUG(@"Download of %@ finished", [self.cacheObject.url absoluteString]);
    self.downloading = NO;
    [self.beaconManager pingBeaconForEvent:PHDidPreload withData:nil];
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDidFinishPreloadingNotification object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    PH_DEBUG(@"Download of %@ failed: %@", [self.cacheObject.url absoluteString], error);
    self.downloading = NO;
    [self.beaconManager pingBeaconForEvent:PHDidFailToPreload withData:nil];
    self.error = error;
    [[NSNotificationCenter defaultCenter] postNotificationName:PHDidFailToPreloadNotification object:self];
}

@end
