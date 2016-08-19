//
//  PHBeaconManager.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/18/15.
//
//

#import <Foundation/Foundation.h>
#import "PHBeaconObject.h"

@interface PHBeaconManager : NSObject

@property (nonatomic, retain) PHBeaconObject *beaconObject;

/**
 * Initialize the beacon manager with a beacon object
 *
 * @param beaconObject
 *   The beacon object
 **/
- (id)initWithBeaconObject:(PHBeaconObject *)beaconObject;

/**
 * Ping the supplied beacon, with or without data
 *
 * @param beacon
 *   The beacon to ping
 *
 * @param data
 *   A dictionary of strings or numbers used in url variable substitution
 **/
- (void)pingBeaconForEvent:(PHBeacon)beacon withData:(NSDictionary *)data;

@end
