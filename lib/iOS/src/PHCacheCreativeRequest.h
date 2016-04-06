//
//  PHCacheCreativeRequest.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/13/15.
//
//

#import <Foundation/Foundation.h>
#import "PHAPIRequest.h"
#import "PHPreloader.h"
#import "PHPreloadingObject.h"

@protocol PHCacheCreativeRequestDelegate <NSObject>
@optional

/**
 * Optional delegate method that is called when a cacheCreative
 * request is finished loading
 *
 * @param sender
 *   The cache creative request
 *
 * @param request
 *   The original APIRequest
 **/
- (void)cacheRequestDidFinishLoading:(id)sender request:(PHAPIRequest *)request;

/**
 * Optional delegate method that is called when a cacheCreative
 * request is successful
 *
 * @param sender
 *   The cache creative request
 *
 * @param request
 *   The original APIRequest
 *
 * @param responseData
 *   Dictionary of the API response
 **/
- (void)cacheRequest:(id)sender request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData;

/**
 * Optional delegate method that is called when a cacheCreative
 * request fails
 *
 * @param sender
 *   The cache creative request
 *
 * @param request
 *   The original APIRequest
 *
 * @param error
 *   The error
 **/
- (void)cacheRequest:(id)sender request:(PHAPIRequest *)request didFailWithError:(NSError *)error;


@end

@interface PHCacheCreativeRequest : PHAPIRequest <PHAPIRequestDelegate>

@property (nonatomic, strong) PHPreloader *preloader;

/**
 * Initiates a PHCacheCreativeRequest with an app token and secret
 * and delegate that conforms to the PHCacheCreativeRequestDelegate protocol
 *
 * @param token
 *   The app token
 *
 * @param secret
 *   The app secret
 *
 * @return
 *   A PHCacheCreativeRequest instance
 **/
- (id)initWithApp:(NSString *)token secret:(NSString *)secret delegate:(id)delegate;

@end
