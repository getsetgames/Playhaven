//
//  PHPreloader.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/23/15.
//
//

#import <Foundation/Foundation.h>
#import "PHPreloadingObject.h"


@interface PHPreloader : NSObject

@property (nonatomic, retain) NSMutableArray *queue;

/**
 * Returns a singlton instance of PHPreloader
 **/
+ (id)sharedPreloader;

/**
 * Starts downloading the preloading object and saves to
 * disk upon successful download
 *
 * @param preloadingObject
 *   The preloading object
 **/
- (void)startPreloading:(PHPreloadingObject *)preloadingObject;

/**
 * Removes the specified file from the download queue or disk
 *
 * @param creativeId
 *   ID of the file to be removed
 **/
- (void)removeFileWithId:(NSInteger)creativeId;

/**
 * Resets the download queue and removes all file from 
 * download directory
 **/
- (void)clear;

/**
 * Resets the download queue
 **/
- (void)resetQueue;

/**
 * Convenience method for getting a path to 
 * a specified file
 *
 * @param creativeId
 *   ID of the file to get a path for
 *
 * @return
 *   Full path to the downloaded file
 **/
+ (NSString *)getFullPathFromCreativeId:(NSInteger)creativeId;

/**
 * Convenience method for getting a path to the download directory
 *
 * @return
 *   Path to the download directory
 **/
+ (NSString *)getDownloadDirectory;

/**
 * Convenience method for creating a new array
 * of saved file records from User Defaults
 *
 * @return
 *   A new mutable array of PHCacheObject file records
 *   from User Defaults
 **/
+ (NSMutableArray *)newSavedFilesArray;

/**
 * Convenience method for creating a string used
 * as a paramenter in cacheCreative and content requests
 *
 * @return
 *   A new string representation of the array of 
 *   cached files
 **/
+ (NSString *)cacheQueryString;

@end
