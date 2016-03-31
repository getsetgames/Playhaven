//
//  PHPreloader.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/23/15.
//
//

#import "PHPreloader.h"
#import "PHConstants.h"
#import "PHCacheObject.h"


@implementation PHPreloader

+ (id)sharedPreloader {
    static PHPreloader *preloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preloader = [[self alloc] init];
    });
    return preloader;
}

- (id)init {
    self = [super init];
    if (self){
        _queue = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPreloading:)
                                                     name:PHDidFinishPreloadingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFailToPreload:)
                                                     name:PHDidFailToPreloadNotification
                                                   object:nil];
    }
    return self;
}

- (void)startPreloading:(PHPreloadingObject *)preloadingObject {
    if (![self isInQueue:preloadingObject] && ![self isDownloaded:preloadingObject]) {
        [_queue addObject:preloadingObject];
        [self processNextQueueItem];
    }
}

- (BOOL)isInQueue:(PHPreloadingObject *)preloadingObject {
    BOOL inQueue = NO;
    for (PHPreloadingObject *po in _queue) {
        if (po.cacheObject.creativeId == preloadingObject.cacheObject.creativeId) {
            inQueue = YES;
            break;
        }
    }
    return inQueue;
}

- (BOOL)isDownloaded:(PHPreloadingObject *)preloadingObject {
    BOOL downloaded = NO;
    NSMutableArray *savedFiles = [PHPreloader newSavedFilesArray];
    for (PHCacheObject *cacheObject in savedFiles) {
        if (cacheObject.creativeId == preloadingObject.cacheObject.creativeId) {
            downloaded = YES;
            break;
        }
    }
    return downloaded;
}

- (void)processNextQueueItem {
    if (_queue.count > 0) {
        PHPreloadingObject *activeObject = [_queue objectAtIndex:0];
        if (!activeObject.downloading) {
            [activeObject start];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma Convenience functions

+ (NSString *)getFullPathFromCreativeId:(NSInteger)creativeId {
    NSArray *savedFiles = [PHPreloader newSavedFilesArray];
    for (PHCacheObject *cacheObject in savedFiles) {
        if (cacheObject.creativeId == creativeId) {
            return [NSString stringWithFormat:@"%@/%@", [PHPreloader getDownloadDirectory], cacheObject.fileName];
        }
    }
    return nil;
}

+ (NSString *)getDownloadDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    BOOL isDir;
    NSString *downloadDirectoy = [[paths objectAtIndex:0] stringByAppendingPathComponent:PHDidReceiveDataNotification];
    PH_DEBUG(@"PH download directory: %@", downloadDirectoy);
    if (![fileManager fileExistsAtPath:downloadDirectoy isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:downloadDirectoy withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return downloadDirectoy;
}

+ (NSMutableArray *)newSavedFilesArray {
    NSMutableArray *savedFiles;
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *cacheArrayData = [currentDefaults objectForKey:PH_CACHE_USER_DEFAULT_KEY];
    if (cacheArrayData != nil) {
        NSArray *cacheArray = [NSKeyedUnarchiver unarchiveObjectWithData:cacheArrayData];
        if (cacheArray != nil) {
            savedFiles = [[NSMutableArray alloc] initWithArray:cacheArray];
        } else {
            savedFiles = [[NSMutableArray alloc] init];
        }
        return savedFiles;
    }
    return nil;
}

+ (NSString *)cacheQueryString {
    NSArray *savedFiles = [PHPreloader newSavedFilesArray];
    NSMutableArray *savedFileIds = [[NSMutableArray alloc] init];
    for (PHCacheObject *cacheObject in savedFiles) {
        [savedFileIds addObject:[NSNumber numberWithInteger:cacheObject.creativeId]];
    }
    return [NSString stringWithFormat:@"[%@]", [savedFileIds componentsJoinedByString:@","]];
}

#pragma mark -
#pragma Delete

- (void)removeFileWithId:(NSInteger)creativeId {
    [self removeFileFromQueueWithId:creativeId];
    [self removeFileFromDiskWithId:creativeId];
}

- (void)removeFileFromQueueWithId:(NSInteger)creativeId {
    NSMutableArray *itemsToRemove = [[NSMutableArray alloc] init];
    for (PHPreloadingObject *po in _queue) {
        if (creativeId == po.cacheObject.creativeId) {
            [po stop];
            [itemsToRemove addObject:po];
        }
    }
    [_queue removeObjectsInArray:itemsToRemove];
}

- (void)removeFileFromDiskWithId:(NSInteger)creativeId {
    NSMutableArray *itemsToRemove = [[NSMutableArray alloc] init];
    NSMutableArray *savedFiles = [PHPreloader newSavedFilesArray];
    for (PHCacheObject *cacheObject in savedFiles) {
        if (cacheObject.creativeId == creativeId) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *filePath = [PHPreloader getFullPathFromCreativeId:cacheObject.creativeId];
            NSError *error;
            BOOL success = [fileManager removeItemAtPath:filePath error:&error];
            
            if (success) {
                PH_DEBUG(@"%@ successfully deleted (id:%li)", filePath, (long)cacheObject.creativeId);                
                [itemsToRemove addObject:cacheObject];
            } else {
                PH_DEBUG(@"Could not delete file: %@ (id:%li)", [error localizedDescription], (long)cacheObject.creativeId);
            }
        }
    }
    
    [savedFiles removeObjectsInArray:itemsToRemove];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:savedFiles] forKey:PH_CACHE_USER_DEFAULT_KEY];
    
}

- (void)clear {
    [self resetQueue];
    [self removeFiles];
    [self resetUserDefaultReferences];
}

- (void)resetQueue {
    for (PHPreloadingObject *po in _queue) {
        [po stop];
    }
    [_queue removeAllObjects];
}

- (void)removeFiles {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directory = [PHPreloader getDownloadDirectory];
    NSError *error = nil;
    for (NSString *file in [fileManager contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, file] error:&error];
        if (!success || error) {
            PH_DEBUG(@"Error deleting downloaded files!: %@", error);
        }
    }
}

- (void)resetUserDefaultReferences {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PH_CACHE_USER_DEFAULT_KEY];
}

#pragma mark -
#pragma mark PHPreloadingObject notification events

- (void)itemDidFinishPreloading:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    [_queue removeObject:preloadingObject];
    [self processNextQueueItem];
}

- (void)itemDidFailToPreload:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    [_queue removeObject:preloadingObject];
    [self processNextQueueItem];
}

@end
