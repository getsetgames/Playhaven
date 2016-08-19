/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHPublisherContentRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>

#import "PHConstants.h"
#import "PHContent.h"
#import "PHContentView.h"
#import "PHPublisherContentRequest.h"
#import "PHStringUtil.h"
#import "PHPublisherContentRequest+Private.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "NSObject+QueryComponents.h"
#import "PHAPIRequest+Private.h"

#define PUBLISHER_TOKEN @"PUBLISHER_TOKEN"
#define PUBLISHER_SECRET @"PUBLISHER_SECRET"

static NSString *kPHApplicationTestToken  = @"TEST_TOKEN";
static NSString *kPHApplicationTestSecret = @"TEST_SECRET";
static NSString *kPHTestPlacement = @"test_placement";
static NSString *kPHTestContentID = @"test_content_id";
static NSString *const kPHTestMessageID = @"87345";
static NSString *const kPHTestCampaignID = @"2342348";

@interface PHPublisherContentRequest (TestMethods)
@property (nonatomic, readonly) PHPublisherContentRequestState state;
- (BOOL)setPublisherContentRequestState:(PHPublisherContentRequestState)state;

- (void)requestPurchases:(NSDictionary *)queryParameters callback:(NSString *)callback source:(PHContentView *)source;
@end

@interface PHContentTest : XCTestCase @end
@interface PHContentViewTest : XCTestCase @end
@interface PHContentViewRedirectTest : XCTestCase {
    PHContent *_content;
    PHContentView *_contentView;
    BOOL _didDismiss, _didLaunch;
}
@end

@interface PHContentViewRedirectRecyclingTest : XCTestCase {
    BOOL _shouldExpectParameter;
}
@end

@interface PHPublisherContentRequestTest : XCTestCase @end
@interface PHPublisherContentPurchasesTest : XCTestCase @end
@interface PHPublisherContentRequestPreservationTest : XCTestCase @end
@interface PHPublisherContentPreloadTest : XCTestCase {
    PHPublisherContentRequest *_request;
    BOOL _didPreload;
}
@end

@interface PHPublisherContentPreloadParameterTest : XCTestCase @end
@interface PHPublisherContentStateTest : XCTestCase @end

@interface PHPublisherContentRequestMock : PHPublisherContentRequest
@end

@implementation PHPublisherContentRequestMock
+ (NSDictionary *)identifiers
{
    return @{@"ifa" : @"345678KLFL8768HJK"};
}
@end

@implementation PHContentTest

- (void)testContent
{
    NSString
        *empty   = @"{}",
        *keyword = @"{\"frame\":\"PH_FULLSCREEN\",\"url\":\"http://google.com\",\"transition\":\"PH_MODAL\",\"context\":{\"awesome\":\"awesome\"}}",
        *rect    = @"{\"frame\":{\"PH_LANDSCAPE\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"PH_PORTRAIT\":{\"x\":40,\"y\":60,\"w\":240,\"h\":340}},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"}}";

    NSData *emptyData = [empty dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keywordData = [keyword dataUsingEncoding:NSUTF8StringEncoding];
    NSData *rectData = [rect dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary
    *emptyDict   = emptyData ? [NSJSONSerialization JSONObjectWithData:emptyData options:0 error:nil] : nil,
    *keywordDict = keywordData ? [NSJSONSerialization JSONObjectWithData:keywordData options:0 error:nil] : nil,
    *rectDict    = rectData ? [NSJSONSerialization JSONObjectWithData:rectData options:0 error:nil] : nil;

    PHContent *emptyUnit = [PHContent contentWithDictionary:emptyDict];
    XCTAssertNil(emptyUnit, @"Empty definition should result in nil!");

    PHContent *keywordUnit = [PHContent contentWithDictionary:keywordDict];
    XCTAssertNotNil(keywordUnit, @"Keyword definition should result in unit!");

    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect theExpectedFrame = CGRectZero;
    theExpectedFrame.size = applicationFrame.size;
    XCTAssertTrue(CGRectEqualToRect([keywordUnit frameForOrientation:UIInterfaceOrientationPortrait], theExpectedFrame),
                 @"Frame mismatch from keyword. Got %@", NSStringFromCGRect(theExpectedFrame));

    NSURL *adURL = [NSURL URLWithString:@"http://google.com"];
    XCTAssertTrue([keywordUnit.URL isEqual:adURL],
                 @"URL mismatch. Expected %@ got %@", adURL, keywordUnit.URL);

    XCTAssertTrue(keywordUnit.transition == PHContentTransitionModal,
                 @"Transition type mismatched. Expected %d got %d", PHContentTransitionModal, keywordUnit.transition);

    XCTAssertNotNil([keywordUnit.context valueForKey:@"awesome"],
                   @"Expected payload key not found!");

    PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
    XCTAssertNotNil(rectUnit, @"Keyword definition should result in unit!");

    CGRect expectedLandscapeFrame = CGRectMake(60,40,200,400);
    XCTAssertTrue(CGRectEqualToRect([rectUnit frameForOrientation:UIInterfaceOrientationLandscapeLeft], expectedLandscapeFrame),
                 @"Frame mismatch from keyword. Got %@", NSStringFromCGRect([rectUnit frameForOrientation:UIInterfaceOrientationLandscapeLeft]));

}

- (void)testCloseButtonDelayParameter
{
  PHContent *content = [[PHContent alloc] init];
  XCTAssertTrue(content.closeButtonDelay == 10.0f, @"Default closeButton delay value incorrect!");

  NSString *rect = @"{\"frame\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"},\"close_delay\":23}";

    NSData *rectData = [rect dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *rectDict = rectData ? [NSJSONSerialization JSONObjectWithData:rectData options:0 error:nil] : nil;

  PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
  XCTAssertTrue(rectUnit.closeButtonDelay == 23.0f, @"Expected 23 got %f", content.closeButtonDelay);
}

- (void)testCloseButtonUrlParameter
{
  PHContent *content = [[PHContent alloc] init];
  XCTAssertTrue(content.closeButtonURLPath == nil, @"CloseButtonURLPath property not available");

  NSString *rect = @"{\"frame\":{\"x\":60,\"y\":40,\"w\":200,\"h\":400},\"url\":\"http://google.com\",\"transition\":\"PH_DIALOG\",\"context\":{\"awesome\":\"awesome\"},\"close_ping\":\"http://playhaven.com\"}";

    NSData *rectData = [rect dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *rectDict = rectData ? [NSJSONSerialization JSONObjectWithData:rectData options:0 error:nil] : nil;

  PHContent *rectUnit = [PHContent contentWithDictionary:rectDict];
  XCTAssertTrue([rectUnit.closeButtonURLPath isEqualToString:@"http://playhaven.com"], @"Expected 'http://playhaven.com got %@", content.closeButtonURLPath);
}
@end

@implementation PHContentViewTest

- (void)testcontentView
{
    PHContent *content = [[PHContent alloc] init];

    PHContentView *contentView = [[PHContentView alloc] initWithContent:content];
    XCTAssertTrue([contentView respondsToSelector:@selector(show:)], @"Should respond to show selector");
    XCTAssertTrue([contentView respondsToSelector:@selector(dismiss:)], @"Should respond to dismiss selector");
}
@end

@implementation PHContentViewRedirectTest

- (void)setUp
{
    _content = [[PHContent alloc] init];

    _contentView = [[PHContentView alloc] initWithContent:_content];
    [_contentView redirectRequest:@"ph://dismiss" toTarget:self action:@selector(dismissRequestCallback:)];
    [_contentView redirectRequest:@"ph://launch" toTarget:self action:@selector(launchRequestCallback:)];
}

- (void)testRegularRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssertTrue(result, @"_contentView should open http://google.com in webview!");
}

- (void)testDismissRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://dismiss"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssertFalse(result, @"_contentView should not open ph://dismiss in webview!");
}

- (void)dismissRequestCallback:(NSDictionary *)parameters
{
    XCTAssertNil(parameters, @"request with no parameters returned parameters!");
}

- (void)testLaunchRequest
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://launch?context=%7B%22url%22%3A%22http%3A%2F%2Fadidas.com%22%7D"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:request navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssertFalse(result, @"_contentView should not open ph://dismiss in webview!");
}

- (void)launchRequestCallback:(NSDictionary *)parameters
{
    XCTAssertNotNil(parameters, @"request with parameters returned no parameters!");
    XCTAssertTrue([@"http://adidas.com" isEqualToString:[parameters valueForKey:@"url"]],
                 @"Expected 'http://adidas.com' got %@ as %@",
                 [parameters valueForKey:@"url"], [[parameters valueForKey:@"url"] class]);

}
@end

@implementation PHContentViewRedirectRecyclingTest
- (void)testRedirectRecycling
{
    PHContent     *content     = [[PHContent alloc] init];
    PHContentView *contentView = [[PHContentView alloc] initWithContent:content];

    [contentView redirectRequest:@"ph://test" toTarget:self action:@selector(handleTest:)];

    NSURLRequest *request  =
            [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://test?context=%7B%22url%22%3A%22http%3A%2F%2Fadidas.com%22%7D"]];
    _shouldExpectParameter = YES;
    XCTAssertFalse([contentView webView:nil
            shouldStartLoadWithRequest:request
                        navigationType:UIWebViewNavigationTypeLinkClicked], @"Didn't redirect to dispatch handler");

    // NOTE: This rest ensures that invocation objects are being properly recycled.
    NSURLRequest *nextRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://test"]];
    _shouldExpectParameter = NO;
    XCTAssertFalse([contentView webView:nil
            shouldStartLoadWithRequest:nextRequest
                        navigationType:UIWebViewNavigationTypeLinkClicked], @"Didn't redirect next request to dispatch handler");
}

- (void)handleTest:(NSDictionary *)parameters
{
    NSString *url = [parameters valueForKey:@"url"];
    if (_shouldExpectParameter) {
        XCTAssertNotNil(url, @"Expected parameter was not present");
    } else  {
        XCTAssertNil(url, @"Expected nil returned a value");
    }
}
@end

@implementation PHPublisherContentRequestTest

- (void)setUp
{
    [super setUp];
    
    [PHAPIRequest setCustomUDID:nil];
}

- (void)tearDown
{
    [super tearDown];
    
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");

    // Cancel the request to remove it from the cache
    [theTestRequest cancel];
}

- (void)testIDFAParameter
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];
    
    PHPublisherContentRequest *theRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    if (PH_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        XCTAssertTrue([theIDFA length] > 0, @"Invalid IDFA value: %@", theIDFA);

        NSString *theIDFAParameter = [NSString stringWithFormat:@"ifa=%@", theIDFA];
        XCTAssertTrue([theRequestURL rangeOfString:theIDFAParameter].length > 0, @"IDFA is missed"
                    " from the request URL");
    
    }
    else
    {
        XCTAssertNil(theIDFA, @"IDFA is not available on iOS earlier than 6.0.");
        XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
    }

    // Restore opt out status
    [PHAPIRequest setOptOutStatus:theOptOutFlag];
}

- (void)testNoIDFAParameter
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:YES];
    
    PHPublisherContentRequest *theRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    XCTAssertNil(theIDFA, @"No IDFA parameter is expected on when opt out status is YES!");
    XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"No IDFA parameter is expected"
                " on when opt out status is YES!");

    // Restore opt out status
    [PHAPIRequest setOptOutStatus:theOptOutFlag];
}

- (void)testAnimatedParameter
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:PUBLISHER_TOKEN
                                                                           secret:PUBLISHER_SECRET];
    XCTAssertTrue(request.animated, @"Default state of animated property should be TRUE");

    request.animated = NO;
    XCTAssertFalse(request.animated, @"Animated property not set!");
}

- (void)testRequestParametersCase1
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:PUBLISHER_TOKEN
                                                                           secret:PUBLISHER_SECRET];
    request.placement = @"placement_id";

    NSString *requestURLString = [[self URLForRequest:request] absoluteString];
    NSDictionary *dictionary = [request signedParameters];
    XCTAssertNotNil([dictionary valueForKey:@"placement_id"], @"Expected 'placement_id' parameter.");

    NSString *parameterString = [request signedParameterString];
    NSString *placementParam  = @"placement_id=placement_id";
    XCTAssertFalse([parameterString rangeOfString:placementParam].location == NSNotFound,
                  @"Placment_id parameter not present!");

    NSDictionary *signedParameters  = [request signedParameters];

#if PH_USE_MAC_ADDRESS == 1
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        NSString *mac   = [signedParameters valueForKey:@"mac"];
        XCTAssertNotNil(mac, @"MAC param is missing!");
        XCTAssertFalse([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param is missing!");
    }
#else
    NSString *mac   = [signedParameters valueForKey:@"mac"];
    STAssertNil(mac, @"MAC param is present!");
    STAssertTrue([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param exists when it shouldn't.");
#endif
}

- (void)testRequestParametersCase2
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                                   placement:kPHTestPlacement
                                                    delegate:nil];
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];

    XCTAssertEqualObjects(theTestRequest.placement, kPHTestPlacement, @"The request's placement "
            "doesn't mach the one passed in the initializer");
    XCTAssertNil(theTestRequest.delegate, @"");

    NSNumber *theSessionDuration = [theTestRequest.additionalParameters objectForKey:@"stime"];
    XCTAssertNotNil(theSessionDuration, @"Missed mandatory parameter!");
    XCTAssertTrue(0 <= [theSessionDuration intValue], @"Incorrect session duration value");

    NSNumber *theRequestPreloaded = [theTestRequest.additionalParameters objectForKey:@"preload"];
    XCTAssertNotNil(theRequestPreloaded, @"Missed mandatory parameter!");
    XCTAssertFalse([theSessionDuration boolValue], @"Request is not preloaded");

    NSNumber *theIsaParameter = [theTestRequest.additionalParameters objectForKey:@"isa"];
    XCTAssertNotNil(theIsaParameter, @"Missed mandatory parameter!");

    NSString *thePlacementParameter =
                     [theTestRequest.additionalParameters objectForKey:@"placement_id"];

    XCTAssertEqualObjects(thePlacementParameter, kPHTestPlacement, @"Missed mandatory parameter!");

    NSString *theContentIDParameter =
                     [theTestRequest.additionalParameters objectForKey:@"content_id"];

    XCTAssertEqualObjects(theContentIDParameter, @"", @"Missed mandatory parameter!");
	
    NSString *theMessageIDParameter = [theTestRequest.additionalParameters objectForKey:
                @"message_id"];

    XCTAssertNil(theMessageIDParameter, @"message_id parameter should not be specified for content"
                " requests which are created with placement");

    NSString *theRequestQuery = [theRequestURL query];

    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"stime=%@",
				theSessionDuration]].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"preload=0"].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"isa="].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id=test_placement"].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"content_id="].length), @"");
	XCTAssertTrue(0 == [theRequestQuery rangeOfString:@"message_id="].length, @"The parameter should"
				" not be specified for content requests which are created with placement");
    XCTAssertTrue((0 == [theRequestQuery rangeOfString:@"campaign_id="].length), @"The parameter "
				"should not be specified for content requests which are created with placement");
}

- (void)testRequestParametersCase3
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                               contentUnitID:kPHTestContentID
                                                   messageID:kPHTestMessageID
												  campaignID:kPHTestCampaignID];

    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    NSString *thePlacementParameter =
                     [theTestRequest.additionalParameters objectForKey:@"placement_id"];

    XCTAssertEqualObjects(thePlacementParameter, @"", @"Missed mandatory parameter!");

    NSString *theMessageIDParameter = [theTestRequest.additionalParameters objectForKey:
									   @"message_id"];
	
    XCTAssertEqualObjects(theMessageIDParameter, kPHTestMessageID, @"Missed message_id parameter!");

    NSString *theRequestQuery = [theRequestURL query];

    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id="].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"content_id=%@",
				kPHTestContentID]].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"message_id=%@",
				kPHTestMessageID]].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:
				@"campaign_id=%@", kPHTestCampaignID]].length), @"");
}

- (void)testNoCampaignIDParameter
{
    PHPublisherContentRequest *theTestRequest =
                    [PHPublisherContentRequest requestForApp:kPHApplicationTestToken
                                                      secret:kPHApplicationTestSecret
                                               contentUnitID:kPHTestContentID
                                                   messageID:kPHTestMessageID
												  campaignID:nil];

    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    NSString *theRequestQuery = [theRequestURL query];

    XCTAssertTrue((0 < [theRequestQuery rangeOfString:@"placement_id="].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"content_id=%@",
				kPHTestContentID]].length), @"");
    XCTAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"message_id=%@",
				kPHTestMessageID]].length), @"");
    XCTAssertTrue((0 == [theRequestQuery rangeOfString:@"campaign_id="].length), @"");
}

- (void)testNoCustomDimensions
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");
    
    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];

    XCTAssertNil(theCustomDimensionsParameter, @"Custom dimensions should not be included in the "
                "content request unless they are set explicitly!");
    XCTAssertTrue(0 == [[theRequestURL query] rangeOfString:@"custom="].length, @"Custom dimensions "
                "should not be included in the content request unless they are set explicitly!");
}

- (void)testValidCustomDimensions
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSString *const kStringDimensionKey1 = @"StringDimensionKey1";
    NSString *const kStringDimensionKey2 = @"StringDimensionKey2";
    NSString *const kNumberDimensionKey1 = @"NumberDimensionKey1";
    NSString *const kNumberDimensionKey2 = @"NumberDimensionKey2";
    NSString *const kNumberDimensionKey3 = @"NumberDimensionKey3";
    NSString *const kNullDimensionKey = @"NullDimensionKey";

    NSString *const kStringDimensionValue1 = @"StringDimensionValue1";
    NSString *const kStringDimensionValue2 = @"StringDimensionValue2";
    NSNumber *const kNumberDimensionValue1 = @(5463);
    NSNumber *const kNumberDimensionValue2 = [NSDecimalNumber numberWithFloat:234652.2345f];
    NSNumber *const kNumberDimensionValue3 = @(YES);
    
    NSDictionary *theDimensionsBulk =
    @{
        kStringDimensionKey2 : kStringDimensionValue2,
        kNumberDimensionKey2 : kNumberDimensionValue2,
        kNumberDimensionKey3 : kNumberDimensionValue3
    };
    
    [theTestRequest addDimensionsFromDictionary:theDimensionsBulk];
    [theTestRequest setDimension:kStringDimensionValue1 forKey:kStringDimensionKey1];
    [theTestRequest setDimension:kNumberDimensionValue1 forKey:kNumberDimensionKey1];
    [theTestRequest setDimension:[NSNull null] forKey:kNullDimensionKey];
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");

    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];
    XCTAssertNotNil(theCustomDimensionsParameter, @"Missed custom dimensions that were set for the"
                "content request!");
    
    NSError *theError = nil;
    NSDictionary *theDeserializedJSON = [NSJSONSerialization JSONObjectWithData:
                [theCustomDimensionsParameter dataUsingEncoding:NSUTF8StringEncoding] options:0
                error:&theError];
    XCTAssertNotNil(theDeserializedJSON, @"Cannot de-serialized custom dimensions: custom value - "
                "%@; error - %@", theCustomDimensionsParameter, theError);
    
    NSDictionary *theExpectedDictionary =
    @{
        kStringDimensionKey1 : kStringDimensionValue1,
        kNumberDimensionKey1 : kNumberDimensionValue1,
        kNullDimensionKey : [NSNull null],
        kStringDimensionKey2 : kStringDimensionValue2,
        kNumberDimensionKey2 : kNumberDimensionValue2,
        kNumberDimensionKey3 : kNumberDimensionValue3
    };
    XCTAssertEqualObjects(theDeserializedJSON, theExpectedDictionary, @"De-serialized dimensions "
                "don't match the original ones that were set on the request object!");

    NSString *theCustomParameter = [NSString stringWithFormat:@"custom=%@",
                [theCustomDimensionsParameter stringByEncodingURLFormat]];
    XCTAssertTrue(0 < [[theRequestURL query] rangeOfString:theCustomParameter].length, @"Missed "
                "custom dimensions that were set for the content request!");
}

- (void)testInvalidCustomDimensionsCase1
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSString *const kDataDimensionKey1 = @"StringDimensionKey1";
    
    [theTestRequest setDimension:[@"testValue" dataUsingEncoding:NSUTF8StringEncoding] forKey:
                kDataDimensionKey1];
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");

    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];

    XCTAssertNil(theCustomDimensionsParameter, @"Custom dimensions should not be included in the "
                "content request as the dimension that was set has unexpected type!");
    XCTAssertTrue(0 == [[theRequestURL query] rangeOfString:@"custom="].length, @"Custom dimensions "
                "should not be included in the content request as the dimension that was set has "
                "unexpected type!");
}

- (void)testInvalidCustomDimensionsCase2
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    NSString *const kSetDimensionKey1 = @"StringDimensionKey1";
    
    [theTestRequest setDimension:[NSSet setWithObject:@"testValue"] forKey:kSetDimensionKey1];
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");

    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];

    XCTAssertNil(theCustomDimensionsParameter, @"Custom dimensions should not be included in the "
                "content request as the dimension that was set has unexpected type!");
    XCTAssertTrue(0 == [[theRequestURL query] rangeOfString:@"custom="].length, @"Custom dimensions "
                "should not be included in the content request as the dimension that was set has "
                "unexpected type!");
}

- (void)testInvalidCustomDimensionsCase3
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    [theTestRequest addDimensionsFromDictionary:@{@(34) : @(234)}];
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");

    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];

    XCTAssertNil(theCustomDimensionsParameter, @"Custom dimensions should not be included in the "
                "content request as the dimension that was set has unexpected type!");
    XCTAssertTrue(0 == [[theRequestURL query] rangeOfString:@"custom="].length, @"Custom dimensions "
                "should not be included in the content request as the dimension that was set has "
                "unexpected type!");
}

- (void)testInvalidCustomDimensionsCase4
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    [theTestRequest addDimensionsFromDictionary:@{@"dateKey" : [NSDate date]}];
    
    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");

    NSString *theCustomDimensionsParameter = [theTestRequest.additionalParameters objectForKey:
                @"custom"];

    XCTAssertNil(theCustomDimensionsParameter, @"Custom dimensions should not be included in the "
                "content request as the dimension that was set has unexpected type!");
    XCTAssertTrue(0 == [[theRequestURL query] rangeOfString:@"custom="].length, @"Custom dimensions "
                "should not be included in the content request as the dimension that was set has "
                "unexpected type!");
}

- (void)testContentRequestHTTPMethod
{
    PHPublisherContentRequest *theTestRequest = [PHPublisherContentRequest requestForApp:
                kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                delegate:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot created test request");
    
    XCTAssertEqual(PHRequestHTTPPost, theTestRequest.HTTPMethod, @"Request method doesn't match the"
                " expected one!");
}

- (void)testLocationParameter {
    PHPublisherContentRequest *theRequest = [PHPublisherContentRequest requestForApp:
                                             kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                                                                            delegate:nil];
    NSDictionary *additionalParameters = [theRequest additionalParameters];
    
    NSString *latParam = additionalParameters[@"lat"];
    NSString *lonParam = additionalParameters[@"lon"];
    NSString *accParam = additionalParameters[@"acc"];
    
    XCTAssertNotNil(latParam, @"Latitude should be present");
    XCTAssertNotNil(lonParam, @"Longitude should be present");
    XCTAssertNotNil(accParam, @"Accuracy should be present");
}

- (void)testLocationOptOut {
    PHPublisherContentRequest *theRequest = [PHPublisherContentRequest requestForApp:
                                             kPHApplicationTestToken secret:kPHApplicationTestSecret placement:kPHTestPlacement
                                                                            delegate:nil];
    [PHAPIRequest setLocationOptOutStatus:YES];
    
    NSDictionary *additionalParameters = [theRequest additionalParameters];
    
    NSString *latParam = additionalParameters[@"lat"];
    NSString *lonParam = additionalParameters[@"lon"];
    NSString *accParam = additionalParameters[@"acc"];
    
    XCTAssertEqualObjects(latParam, @"", @"Latitude should be present, but empty");
    XCTAssertEqualObjects(lonParam, @"", @"Longitude should be present, but empty");
    XCTAssertEqualObjects(accParam, @"", @"Accuracy should be present, but empty");
}

@end

@implementation PHPublisherContentPurchasesTest

- (void)testValidation
{
    NSString *product   = @"com.playhaven.example.candy";
    NSString *name      = @"Delicious Candy";
    NSNumber *quantity  = [NSNumber numberWithInt:1234];
    NSNumber *receipt   = [NSNumber numberWithInt:102930193];
    NSNumber *cookie    = [NSNumber numberWithInt:3423413];

    NSDictionary *thePurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
                @"id" : @"ifa"
    };

    NSDictionary *theInvalidPurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
    };

    NSDictionary *thePurchasesDictionary = @{@"purchases" : @[thePurchase]};

    PHPublisherContentRequest *request = [PHPublisherContentRequestMock requestForApp:
                PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    XCTAssertTrue([request isValidPurchase:thePurchase], @"PHPublisherContentRequest could not "
                "validate valid purchase");
    XCTAssertFalse([request isValidPurchase:theInvalidPurchase], @"PHPublisherContentRequest "
                "validated invalid purchase with missed id field");
    XCTAssertNoThrow([request requestPurchases:thePurchasesDictionary callback:nil source:nil],
                @"Problem processing valid purchases array");
}

- (void)testAlternateValidation
{
    NSString *product   = @"com.playhaven.example.candy";
    NSString *name      = @"Delicious Candy";
    NSNumber *quantity  = [NSNumber numberWithInt:1234];
    NSString *receipt   = @"102930193";
    NSString *cookie    = @"3423413";

    NSDictionary *thePurchase =
    @{
                @"product" : product,
                @"name" : name,
                @"quantity" : quantity,
                @"receipt" : receipt,
                @"sig4" : @"vBxtaXGoO8TZY-vWj0O7VCxaL70",
                @"cookie" : cookie,
                @"id" : @"ifa"
    };

    NSDictionary *thePurchasesDictionary = @{@"purchases" : @[thePurchase]};

    PHPublisherContentRequest *request = [PHPublisherContentRequestMock requestForApp:
                PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    XCTAssertTrue([request isValidPurchase:thePurchase], @"PHPublisherContentRequest could not "
                "validate valid purchase");
    XCTAssertNoThrow([request requestPurchases:thePurchasesDictionary callback:nil source:nil],
                @"Problem processing valid purchases array");
}

@end

@implementation PHPublisherContentRequestPreservationTest

- (void)testPreservation
{
    PHPublisherContentRequest *request                   =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestIdentical          =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestDifferentToken     =
          [PHPublisherContentRequest requestForApp:@"token2" secret:@"secret2" placement:@"placement1" delegate:nil];
    PHPublisherContentRequest *requestDifferentPlacement =
          [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement2" delegate:nil];


    XCTAssertTrue(request == requestIdentical, @"These requests should be the same instance!");
    XCTAssertTrue(request != requestDifferentPlacement, @"These requests should be different!");
    XCTAssertTrue(request != requestDifferentToken, @"These requests should be different!");

    NSString *newDelegate = @"DELEGATE";
    PHPublisherContentRequest *requestNewDelegate = [PHPublisherContentRequest requestForApp:@"token1" secret:@"secret1" placement:@"placement1" delegate:newDelegate];

    XCTAssertTrue((id)requestNewDelegate.delegate == (id)newDelegate, @"This request should have had its delegate reassigned!");
}
@end

@implementation PHPublisherContentPreloadTest

- (void)setUp
{
    _request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                  secret:@"haven1"
                                               placement:@"more_games"
                                                delegate:self];
    _didPreload = NO;
}

- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    _didPreload = YES;
}

- (void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    XCTAssertTrue(FALSE, @"This isn't supposed to happen!");
}

- (void)tearDown
{
    XCTAssertTrue(_didPreload, @"Preloading didn't happen!");
    XCTAssertTrue([_request state] == PHPublisherContentRequestPreloaded,@"Request wasn't preloaded!");
}
@end

@implementation PHPublisherContentPreloadParameterTest

- (void)testPreloadParameterWhenPreloading
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];
    [request preload];
    NSURL *theRequestURL = [self URLForRequest:request];

    NSString *parameters = [theRequestURL absoluteString];
    XCTAssertFalse([parameters rangeOfString:@"preload=1"].location == NSNotFound, @"Expected 'preload=1' in parameter string, did not find it!");
    [request cancel];
}

- (void)testPreloadParameterWhenSending
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];
    [request send];
    NSURL *theRequestURL = [self URLForRequest:request];

    NSString *parameters = [theRequestURL absoluteString];
    XCTAssertFalse([parameters rangeOfString:@"preload=0"].location == NSNotFound, @"Expected 'preload=0' in parameter string, did not find it!");
    [request cancel];
}
@end

@implementation PHPublisherContentStateTest

- (void)testStateChanges
{
    PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                        placement:@"more_games"
                                                                         delegate:nil];

    XCTAssertTrue(request.state == PHPublisherContentRequestInitialized, @"Expected initialized state, got %d", request.state);
    XCTAssertTrue([request setPublisherContentRequestState:PHPublisherContentRequestPreloaded], @"Expected to be able to advance state!");
    XCTAssertFalse([request setPublisherContentRequestState:PHPublisherContentRequestPreloading], @"Expected not to be able to regress state!");

    [request cancel];
}
@end
