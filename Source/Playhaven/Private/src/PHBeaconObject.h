//
//  PHBeaconObject.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/18/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PHBeacon) {
    PHBeaconNone,
    /**
     * Beacon used when creative starts downloading
     **/
    PHDidStartPreloading,
    /**
     * Beacon used when creative finished downloading
     **/
    PHDidPreload,
    /**
     * Beacon used when a preload is canceled
     **/
    PHDidCancelPreload,
    /**
     * Beacon used when a creative fails to preload
     **/
    PHDidFailToPreload
};

@interface PHBeaconObject : NSObject

/**
 * Adds a URLs to the beacon object for the given beacons.
 *
 * @param beacons
 *   Dictionary of beacon names with url values
 **/
- (void)addBeacons:(NSDictionary *)beacons;

/**
 * Adds a URL to the beacon object for the given beacon.
 *
 * @param beacon
 *   The beacon to be added
 *
 * @param urls
 *   Array of urls to be associated with the given beacon
 **/
- (void)addBeacon:(PHBeacon)beacon withURLs:(NSArray *)urls;

/**
 * Adds a URL to the beacon object, which is inferred from the
 * supplied string
 *
 * @param beaconName
 *   The string value of the beacon to be added
 *
 * @param url
 *   Array of urls to be associated with the given beacon
 **/
- (void)addBeaconFromString:(NSString *)beaconName withURLs:(NSArray *)urls;

/**
 * Returns a url associated with a given beacon, or nil if the
 * beacon doesn't exist in the object
 *
 * @param beacon
 *   The beacon
 *
 * @return
 *   The url associated with the given beacon, or nil
 **/
- (NSArray *)getBeaconURLs:(PHBeacon)beacon;

/**
 * Static utility function for extracting variable names from a url
 * Returns a string that occurs between the supplied
 * openString (with offset) and closeString
 *
 * @param s
 *   The string
 *
 * @param openString
 *   The start of the string we're extacting
 *
 * @param closeString
 *   The end of the string we're extracting
 *
 * @param offset
 *   The offset from openString from where we should start our return value
 *
 * @return
 *   The string contained between openString and closeString
 **/
+ (NSString *)getVariableFromURLString:(NSString *)s openString:(NSString *)openString closeString:(NSString *)closeString openOffset:(NSInteger)offset;

/**
 * Creates a new array of URLs with substituted variables
 * Values from a supplied dictionary
 *
 * @param beacon
 *   The beacon
 *
 * @param data
 *   The data to added to the URLs
 */
- (NSArray *)newArrayOfSubstitutedValuesForBeacon:(PHBeacon)beacon withData:(NSDictionary *)data;

@end
