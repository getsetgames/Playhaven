/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013-2014 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHPublisherOpenRequest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "PHTimeInGame.h"
#import "PHNetworkUtil.h"
#import "PHResourceCacher.h"
#import "PHAPIRequest+Private.h"
#import "PHCacheCreativeRequest.h"

static NSString *const kPHTimeZoneKey = @"tz";

static NSString *const kPHResponsePrefixKey = @"prefix";

@interface PHAPIRequest (Private)
- (void)finish;
+ (void)setSession:(NSString *)session;
@end

@implementation PHPublisherOpenRequest

+ (id)requestForApp:(NSString *)token secret:(NSString *)secret delegate:(id<PHAPIRequestDelegate>)delegate {
    PHPublisherOpenRequest *openRequest = [super requestForApp:token secret:secret];
    openRequest.delegate = delegate;
    return openRequest;
}

- (NSDictionary *)additionalParameters
{
    NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionary];

    [additionalParameters setValue:[NSNumber numberWithInteger:[[PHTimeInGame getInstance] getCountSessions]]
                            forKey:@"scount"];
    [additionalParameters setValue:[NSNumber numberWithInt:(int)floor([[PHTimeInGame getInstance] getSumSessionDuration])]
                            forKey:@"ssum"];
    [additionalParameters setObject:[self timeZoneOffsetFromGMTAsString] forKey:kPHTimeZoneKey];
    
    return  additionalParameters;
}

- (NSString *)urlPath
{
    return PH_URL(/v3/publisher/open/);
}

- (PHRequestHTTPMethod)HTTPMethod
{
    return PHRequestHTTPPost;
}

#pragma mark - PHAPIRequest response delegate
- (void)send
{
    [super send];
    [[PHTimeInGame getInstance] gameSessionStarted];
}

- (void)didSucceedWithResponse:(NSDictionary *)responseData
{
    id urlArray = [responseData valueForKey:@"precache"];

    if (urlArray && [urlArray isKindOfClass:[NSArray class]])
        for (id url in urlArray)
            if ([url isKindOfClass:[NSString class]])
                [PHResourceCacher prefetchObject:url];


    NSString *session = (NSString *)[responseData valueForKey:@"session"];
    if (!!session) {
        [PHAPIRequest setSession:session];
    }
    
    // Open request is responsible for setting base URL that is to be used for subsequent requests.
    [self updateBaseURL:responseData[kPHResponsePrefixKey]];

    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }

    // Reset time in game counters;
    [[PHTimeInGame getInstance] resetCounters];
    
    PHSetLocationAccessAllowed([responseData valueForKey:@"location_allow_access"]);
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Ask for location
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined &&
        [responseData valueForKey:@"location_allow_prompt"] &&
        PHGetLocationAccessAllowed()) {
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        self.locationManager.delegate = nil;
        [self finish];
    }
    
    // Check if we should be making cache creative requests
    if ([responseData valueForKey:@"cache_creative"]) {
        PHSetShouldCacheCreative([[responseData valueForKey:@"cache_creative"] boolValue]);
    }
    
    if (PHGetShouldCacheCreative()) {
        //Make cache creative request
        PHCacheCreativeRequest *ccRequest = [[PHCacheCreativeRequest alloc] initWithApp:self.token secret:self.secret delegate:self];
        [ccRequest send];
    }    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status > kCLAuthorizationStatusNotDetermined) {
        [self finish];
    }
}

#pragma mark - Private

- (NSString *)timeZoneOffsetFromGMTAsString
{
    return [NSString stringWithFormat:@"%ld.%ld", (long)([[NSTimeZone systemTimeZone] secondsFromGMT]
                / 3600), (long)(([[NSTimeZone systemTimeZone] secondsFromGMT] % 3600) / 60)];
}

#pragma mark -

- (NSString *)parameterValueWithAPIKeySIDPairs:(NSDictionary *)aDictionary
{
    if (0 == [aDictionary count])
    {
        return nil;
    }
    
    NSMutableArray *theFlatPairs = [NSMutableArray arrayWithCapacity:[aDictionary count]];
    
    for (NSString *theKey in [aDictionary allKeys])
    {
        NSString *theAPIKeySIDEntry = [NSString stringWithFormat:@"{\"api\":\"%@\",\"sid\":\"%@\"}",
                    theKey, aDictionary[theKey]];
        [theFlatPairs addObject:theAPIKeySIDEntry];
    }

    return [NSString stringWithFormat:@"[%@]", [theFlatPairs componentsJoinedByString:@","]];
}

#pragma mark -

- (void)updateBaseURL:(NSString *)aBaseURL
{
    if (0 == [aBaseURL length])
    {
        return;
    }

    NSString *theNormilizedURL = aBaseURL;
    
    // SDK expects base URL without trailing slash.
    if ([aBaseURL hasSuffix:@"/"] )
    {
        theNormilizedURL = [aBaseURL substringWithRange:NSMakeRange(0, aBaseURL.length - 1)];
    }

    NSURL *theBaseURL = [NSURL URLWithString:theNormilizedURL];
    
    if (nil != [theBaseURL scheme] && nil != [theBaseURL host])
    {
        PHSetBaseURL(theNormilizedURL);
    }
    else
    {
        PH_LOG(@"[ERROR] %s Received invalid base URL: %@", __PRETTY_FUNCTION__, aBaseURL);
    }
}

@end
