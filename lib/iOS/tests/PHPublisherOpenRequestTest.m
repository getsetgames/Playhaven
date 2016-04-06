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

 PHPublisherOpenRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "PHAPIRequest+Private.h"
#import "PHConstants.h"

#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"

/*static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestAPIKey3 = @"3bd82eed45a332b8d6b0b241dbcb4c1c";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";
static NSString *const kPHTestSID3 = @"73680618561225652767";*/

static NSString *const kPHTestToken  = @"PUBLISHER_TOKEN";
static NSString *const kPHTestSecret = @"PUBLISHER_SECRET";

@interface PHPublisherOpenRequestTest : XCTestCase
@end

@implementation PHPublisherOpenRequestTest

- (void)setUp
{
    [super setUp];

    // Cancel the request to remove it from the cache
    [[PHPublisherOpenRequest requestForApp:kPHTestToken secret:kPHTestSecret] cancel];
}

- (void)testInstance
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";
    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:(NSString *)token secret:(NSString *)secret];
    NSURL *theRequestURL = [self URLForRequest:request];
    NSString *requestURLString = [theRequestURL absoluteString];

    XCTAssertNotNil(requestURLString, @"Parameter string is nil?");
    XCTAssertFalse([requestURLString rangeOfString:@"token="].location == NSNotFound,
                  @"Token parameter not present!");
    XCTAssertFalse([requestURLString rangeOfString:@"nonce="].location == NSNotFound,
                  @"Nonce parameter not present!");
    XCTAssertFalse([requestURLString rangeOfString:@"sig4="].location == NSNotFound,
                  @"Secret parameter not present!");

    XCTAssertTrue([request respondsToSelector:@selector(send)], @"Send method not implemented!");
}

- (void)testRequestParameters
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];
    NSURL *theRequestURL = [self URLForRequest:request];

    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [theRequestURL absoluteString];

//#define PH_USE_MAC_ADDRESS 1
#if PH_USE_MAC_ADDRESS == 1
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        NSString *mac   = [signedParameters valueForKey:@"mac"];
        XCTAssertNotNil(mac, @"MAC param is missing!");
        XCTAssertFalse([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param is missing: %@", requestURLString);
    }
#else
    NSString *mac   = [signedParameters valueForKey:@"mac"];
    STAssertNil(mac, @"MAC param is present!");
    STAssertTrue([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param exists when it shouldn't: %@", requestURLString);
#endif
}

- (void)testCustomUDID
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];
    NSURL *theRequestURL = [self URLForRequest:request];
    NSString *requestURLString = [theRequestURL absoluteString];

    XCTAssertNotNil(requestURLString, @"Parameter string is nil?");
    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none is set.");

    PHPublisherOpenRequest *request2 = [PHPublisherOpenRequest requestForApp:token secret:secret];
    request2.customUDID = @"CUSTOM_UDID";
    theRequestURL = [self URLForRequest:request2];
    requestURLString = [theRequestURL absoluteString];
    XCTAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                 @"Custom parameter missing when one is set.");
}

- (void)testTimeZoneParameter
{
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    NSURL *theRequestURL = [self URLForRequest:theRequest];
    
    XCTAssertNotNil([theRequest.additionalParameters objectForKey:@"tz"], @"Missed time zone!");
    XCTAssertTrue(0 < [[theRequestURL absoluteString] rangeOfString:@"tz="].length, @"Missed time "
                "zone!");

    NSScanner *theTimeZoneScanner = [NSScanner scannerWithString:[theRequestURL absoluteString]];

    XCTAssertTrue([theTimeZoneScanner scanUpToString:@"tz=" intoString:NULL], @"Missed time zone!");
    XCTAssertTrue([theTimeZoneScanner scanString:@"tz=" intoString:NULL], @"Missed time zone!");
    
    float theTimeOffset = 0;
    XCTAssertTrue([theTimeZoneScanner scanFloat:&theTimeOffset], @"Missed time zone!");
    
    XCTAssertTrue(- 11 <= theTimeOffset && theTimeOffset <= 14, @"Incorrect time zone offset");
}

- (void)testHTTPMethod
{
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    XCTAssertNotNil(theRequest, @"");
    
    XCTAssertEqual(PHRequestHTTPPost, theRequest.HTTPMethod, @"HTTPMethod of the request doesn't "
                "match the expected one!");
}

- (void)testCacheCreativeConditional {
    PHPublisherOpenRequest *openRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:kPHTestSecret];
    XCTAssertNotNil(openRequest, @"");
    
    BOOL initialCacheCreativeSetting = PHGetShouldCacheCreative();
    XCTAssertFalse(initialCacheCreativeSetting, @"Initial cache creative setting should be false");
    
    [openRequest didSucceedWithResponse:@{@"cache_creative": @YES}];
    
    BOOL newCacheCreativeSetting = PHGetShouldCacheCreative();
    XCTAssertTrue(newCacheCreativeSetting, @"Cache creative setting should be true after response");
    
    [openRequest didSucceedWithResponse:@{@"cache_creative": @NO}];
    
    BOOL anotherNewCacheCreativeSetting = PHGetShouldCacheCreative();
    XCTAssertFalse(anotherNewCacheCreativeSetting, @"Cache creative setting should be false after response");
}


#pragma mark - Base URL Test

- (void)testUpdatingBaseURL
{
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    XCTAssertNotNil(theRequest, @"");
    
    NSString *theOriginalURL = PHGetBaseURL();
    XCTAssertTrue([[theRequest urlPath] hasPrefix:theOriginalURL], @"The request's urlPath (%@) is "
                "expected to start with: %@", [theRequest urlPath], theOriginalURL);
    
    NSString *theTestBaseURL = @"http://testHost.com";
    [theRequest didSucceedWithResponse:@{@"prefix" : theTestBaseURL}];
    XCTAssertTrue([[theRequest urlPath] hasPrefix:theTestBaseURL], @"The request's urlPath (%@) is "
                "expected to start with: %@", [theRequest urlPath], theTestBaseURL);

    // Make sure that trailing slash is properly removed by SDK
    NSString *theBaseURLWithTrailingSlash = @"http://testHost2.com/";
    [theRequest didSucceedWithResponse:@{@"prefix" : theBaseURLWithTrailingSlash}];
    XCTAssertEqualObjects(PHGetBaseURL(), @"http://testHost2.com", @"Base URL should not end with a "
                "slash!");
    
    // Restore the original base URL
    [theRequest didSucceedWithResponse:@{@"prefix" : theOriginalURL}];
    XCTAssertTrue([[theRequest urlPath] hasPrefix:theOriginalURL], @"The request's urlPath (%@) is "
                "expected to start with: %@", [theRequest urlPath], theOriginalURL);

    // Make sure that invalid URL is not set as a base URL of the SDK
    NSString *theCorruptedURL = @"http:$testHost.com";
    [theRequest didSucceedWithResponse:@{@"prefix" : theCorruptedURL}];
    XCTAssertTrue([[theRequest urlPath] hasPrefix:theOriginalURL], @"The request's urlPath (%@) is "
                "expected to start with: %@", [theRequest urlPath], theOriginalURL);
}

#pragma mark -

- (NSDictionary *)responseDictionaryWithJSONFileName:(NSString *)aFileName
{
    NSError *theError = nil;
    NSString *theStubResponse = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:
                [self class]] URLForResource:aFileName withExtension:@"json"] encoding:
                NSUTF8StringEncoding error:&theError];
    XCTAssertNotNil(theStubResponse, @"Cannot create data with stub response!");
    
    NSData *theStubResponseData = [theStubResponse dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *theResponseDictionary = theStubResponseData ? [NSJSONSerialization JSONObjectWithData:theStubResponseData options:0 error:nil] : nil;
    XCTAssertNotNil(theStubResponse, @"Cannot parse stub response!");

    return theResponseDictionary[@"response"];
}

@end
