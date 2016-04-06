//
//  PHCacheObject.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/2/15.
//
//

#import <Foundation/Foundation.h>

@interface PHCacheObject : NSObject

@property (nonatomic, assign) NSInteger creativeId;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *fileName;

/**
 * Initiates a PHCacheObject with a url and a creativeId -
 * fileName is derived from url
 *
 * @param url
 *   Origin url of the file to download
 *
 * @param creativeId
 *   Unique ID for the creative
 *
 * @return
 *   A PHCacheObject instance
 **/
- (id)initWithURLString:(NSURL *)url creativeId:(NSInteger)creativeId;

@end
