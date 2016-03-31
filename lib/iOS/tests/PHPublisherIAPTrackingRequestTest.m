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

 PHPublisherIAPTrackingRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 2/24/2012.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PlayHavenSDK.h"
#import "SenTestCase+PHAPIRequestSupport.h"

@interface PHPublisherIAPTrackingRequestTest : XCTestCase
@end

@implementation PHPublisherIAPTrackingRequestTest

- (void)testConstructors
{
    PHPublisherIAPTrackingRequest *request;

    request = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET"];
    XCTAssertNotNil(request, @"Expected request to exist!");


    NSString *product  = @"com.playhaven.item";
    NSInteger quantity = 1;
    request = [PHPublisherIAPTrackingRequest requestForApp:@"APP"
                                                    secret:@"SECRET"
                                                   product:product
                                                  quantity:quantity
                                                resolution:PHPurchaseResolutionBuy
                                               receiptData:nil];
    XCTAssertNotNil(request, @"Expected request to exist!");

    request = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET" product:product quantity:quantity error:PHCreateError(PHIAPTrackingSimulatorErrorType) receiptData:nil];
    XCTAssertNotNil(request, @"Expected request to exist!");
}

- (void)testCookie
{
    PHPublisherIAPTrackingRequest *request = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET" product:@"PRODUCT" quantity:1 resolution:PHPurchaseResolutionBuy receiptData:nil];
    [request send];
    NSString *theRequestURLString = [[self URLForRequest:request] absoluteString];
    XCTAssertTrue([theRequestURLString rangeOfString:@"cookie"].location == NSNotFound, @"expected no cookie string parameterString: %@", theRequestURLString);
    [request cancel];

    [PHPublisherIAPTrackingRequest setConversionCookie:@"COOKIE" forProduct:@"PRODUCT"];

    PHPublisherIAPTrackingRequest *request2a = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET" product:@"PRODUCT_OTHER" quantity:1 resolution:PHPurchaseResolutionBuy receiptData:nil];
    [request2a send];
    theRequestURLString = [[self URLForRequest:request2a] absoluteString];
    XCTAssertTrue([theRequestURLString rangeOfString:@"cookie"].location == NSNotFound, @"expected no cookie string parameterString: %@", theRequestURLString);
    [request2a cancel];

    PHPublisherIAPTrackingRequest *request2 = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET" product:@"PRODUCT" quantity:1 resolution:PHPurchaseResolutionBuy receiptData:nil];
    [request2 send];
    theRequestURLString = [[self URLForRequest:request2] absoluteString];
    XCTAssertTrue([theRequestURLString rangeOfString:@"cookie"].location != NSNotFound, @"expected cookie string parameterString: %@", theRequestURLString);
    [request2 cancel];

    PHPublisherIAPTrackingRequest *request3 = [PHPublisherIAPTrackingRequest requestForApp:@"APP" secret:@"SECRET" product:@"PRODUCT" quantity:1 resolution:PHPurchaseResolutionBuy receiptData:nil];
    theRequestURLString = [[self URLForRequest:request3] absoluteString];
    [request3 send];
    XCTAssertTrue([theRequestURLString rangeOfString:@"cookie"].location == NSNotFound, @"cookie should only exist once! parameterString: %@", theRequestURLString);
    [request3 cancel];
}

- (void)testRequestParameters
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherIAPTrackingRequest *request = [PHPublisherIAPTrackingRequest requestForApp:token secret:secret];

    NSURL *theRequestURL = [self URLForRequest:request];
    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [theRequestURL absoluteString];

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

- (void)testNoIDFAParameterWithOptedInUser
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];

    PHPublisherIAPTrackingRequest *theTestRequest = [PHPublisherIAPTrackingRequest requestForApp:
                @"APP" secret:@"SECRET" product:@"PRODUCT" quantity:1 resolution:
                PHPurchaseResolutionBuy receiptData:nil];
    XCTAssertNotNil(theTestRequest, @"Cannot create request instance with test parameters");
    
    NSString *theRequestURL = [[self URLForRequest:theTestRequest] absoluteString];
    NSDictionary *theSignedParameters = [theTestRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    XCTAssertNil(theIDFA, @"IDFA should not be included in the request!");
    XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"IDFA should not be included "
                "in the request!");

    // Restore opt out status
    [PHAPIRequest setOptOutStatus:theOptOutFlag];
}

@end
