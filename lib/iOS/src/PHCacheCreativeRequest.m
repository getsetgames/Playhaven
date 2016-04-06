//
//  PHCacheCreativeRequest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/13/15.
//
//

#import "PHCacheCreativeRequest.h"
#import "PHConstants.h"
#import "PHAPIRequest+Private.h"
#import "PHPreloader.h"
#import "PHCacheObject.h"
#import "PHBeaconObject.h"
#import "PHTimeInGame.h"

@interface PHCacheCreativeRequest() {
    id <PHCacheCreativeRequestDelegate> _requestDelegate;
}

@end

static NSString *const kPHSessionDurationKey  = @"stime";

@implementation PHCacheCreativeRequest

- (id)initWithApp:(NSString *)token secret:(NSString *)secret delegate:(id)delegate {
    self = [super initWithApp:token secret:secret];
    if (self != nil) {
        [super setDelegate:self];
        _requestDelegate = delegate;
    }
    return self;
}

- (NSString *)urlPath {
    return PH_URL(/v5/publisher/cache/);
}

- (PHRequestHTTPMethod)HTTPMethod {
    return PHRequestHTTPGet;
}

- (NSDictionary *)additionalParameters {
    
    NSMutableDictionary *additionalParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:(int)floor([[PHTimeInGame getInstance] getCurrentSessionDuration])], kPHSessionDurationKey, nil];
    
    [additionalParams setObject:[PHPreloader cacheQueryString] forKey:@"preloaded_ids"];
    
    return additionalParams;
}

- (void)removeStaleCacheItems:(NSArray *)ids {
    NSMutableArray *savedItems = [PHPreloader newSavedFilesArray];
    for (PHCacheObject *cacheObject in savedItems) {
        NSInteger creativeId = cacheObject.creativeId;
        if (![ids containsObject:[NSNumber numberWithInteger:creativeId]]) {
            [self.preloader removeFileWithId:creativeId];
        }
    }
}

#pragma mark -
#pragma mark PHAPIRequest delegate methods

- (void)requestDidFinishLoading:(PHAPIRequest *)request {
    if ([_requestDelegate respondsToSelector:@selector(cacheRequestDidFinishLoading:request:)]) {
        [_requestDelegate cacheRequestDidFinishLoading:self request:request];
    }
}

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData {
    self.preloader = [PHPreloader sharedPreloader];
    
    NSMutableArray *currentCacheIds = [[NSMutableArray alloc] init];
    for (NSDictionary *cacheItem in [responseData objectForKey:@"cache"]) {
        NSInteger creativeId = [[cacheItem objectForKey:@"creative_id"] integerValue];
        [currentCacheIds addObject:[NSNumber numberWithInteger:creativeId]];
        
        if ([cacheItem objectForKey:@"url"]) {
            PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
            [beaconObject addBeacons:[cacheItem objectForKey:@"beacons"]];
            PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
            
            PHPreloadingObject *preloadingObject = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager
                                                                                                 url:[NSURL URLWithString:[cacheItem objectForKey:@"url"]]
                                                                                          creativeId:creativeId];
            [self.preloader startPreloading:preloadingObject];
        }
    }
    
    if ([_requestDelegate respondsToSelector:@selector(cacheRequest:request:didSucceedWithResponse:)]) {
        [_requestDelegate cacheRequest:self request:request didSucceedWithResponse:responseData];
    }
    
    [self removeStaleCacheItems:currentCacheIds];
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error {
    if ([_requestDelegate respondsToSelector:@selector(cacheRequest:request:didFailWithError:)]) {
        [_requestDelegate cacheRequest:self request:request didFailWithError:error];
    }
}

@end
