//
//  PHPreloadingObject.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/23/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PHBeaconManager.h"
#import "PHCacheObject.h"

extern NSString * const PHDidStartPreloadingNotification;
extern NSString * const PHDidFinishPreloadingNotification;
extern NSString * const PHDidFailToPreloadNotification;
extern NSString * const PHDidReceiveDataNotification;


@interface PHPreloadingObject : NSObject

@property (nonatomic, retain) PHBeaconManager *beaconManager;
@property (nonatomic, retain) PHCacheObject *cacheObject;
@property (nonatomic, assign) BOOL downloading;
@property (nonatomic, assign) CGFloat percentLoaded;
@property (nonatomic, retain) NSError *error;

/**
 * Initiates a PHPreloadingObject with a beacon manager
 * And the URL of a file that it should cache
 *
 * @param beaconManager
 *   The beacon manager
 *
 * @param url
 *   The url to be preloaded
 *
 * @return
 *   A PHPreloadingObject instance
 **/
- (id)initWithBeaconManager:(PHBeaconManager *)beaconManager url:(NSURL *)url creativeId:(NSInteger)creativeId;

/**
 * Starts the download process
 **/
- (void)start;

/**
 * Cancels the download
 **/
- (void)stop;


@end
