/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2014 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHEventRequestTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/27/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PlayHavenSDK.h"
#import "PHAPIRequest+Private.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "NSObject+QueryComponents.h"

static NSString *const kPHEventRequestTestToken  = @"EventRequestTestToken";
static NSString *const kPHEventRequestTestSecret = @"EventRequestTestSecret";

static NSString *const kPHTestEventPropertyKey1 = @"EventPropertyKey1";
static NSString *const kPHTestEventPropertyKey2 = @"EventPropertyKey2";
static NSString *const kPHTestEventPropertyKey3 = @"EventPropertyKey3";
static NSString *const kPHTestEventPropertyKey4 = @"EventPropertyKey4";
static NSString *const kPHTestEventPropertyValue1 = @"EventPropertyValue1";
static NSString *const kPHTestEventPropertyValue2 = @"EventPropertyValue2";
static NSString *const kPHTestEventPropertyValue3 = @"±!@#$%^&*(+_)(GVL S AJUCBAIU";

@interface PHEventRequestTest : XCTestCase
@end

@implementation PHEventRequestTest

- (void)testCreationWithClassMethod
{
    XCTAssertNil([PHEventRequest requestForApp:nil secret:nil event:nil], @"Event request should not"
                " be created since all request parameters are mandatory!");
    XCTAssertNil([PHEventRequest requestForApp:kPHEventRequestTestToken secret:nil event:nil],
                @"Event request should not be created since all request parameters are mandatory!");
    XCTAssertNil([PHEventRequest requestForApp:nil secret:kPHEventRequestTestSecret event:nil],
                @"Event request should not be created since all request parameters are mandatory!");

    NSDictionary *theProperties = @{kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1};
    PHEvent *theTestEvent = [PHEvent eventWithProperties:theProperties];
    XCTAssertNotNil(theTestEvent, @"Cannot create event necessary for the test!");

    XCTAssertNil([PHEventRequest requestForApp:nil secret:nil event:theTestEvent], @"Event request "
                "should not be created since all request parameters are mandatory!");

    XCTAssertNil([PHEventRequest requestForApp:kPHEventRequestTestToken secret:
                kPHEventRequestTestSecret event:nil], @"Event request should not be created since "
                "all request parameters are mandatory!");
    XCTAssertNotNil([PHEventRequest requestForApp:kPHEventRequestTestToken secret:
                kPHEventRequestTestSecret event:theTestEvent], @"Cannot create event request!");
}

- (void)testCreationWithInitializer
{
    XCTAssertNil([[PHEventRequest alloc] initWithApp:nil secret:nil event:nil], @"Event request "
                "should not be created since all request parameters are mandatory!");
    XCTAssertNil([[PHEventRequest alloc] initWithApp:kPHEventRequestTestToken secret:nil event:nil],
                @"Event request should not be created since all request parameters are mandatory!");
    XCTAssertNil([[PHEventRequest alloc] initWithApp:nil secret:kPHEventRequestTestSecret event:nil],
                @"Event request should not be created since all request parameters are mandatory!");

    NSDictionary *theProperties = @{kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1};
    PHEvent *theTestEvent = [PHEvent eventWithProperties:theProperties];
    XCTAssertNotNil(theTestEvent, @"Cannot create event necessary for the test!");

    XCTAssertNil([[PHEventRequest alloc] initWithApp:nil secret:nil event:theTestEvent], @"Event request "
                "should not be created since all request parameters are mandatory!");

    XCTAssertNil([[PHEventRequest alloc] initWithApp:kPHEventRequestTestToken secret:
                kPHEventRequestTestSecret event:nil], @"Event request should not be created since "
                "all request parameters are mandatory!");
    XCTAssertNotNil([[PHEventRequest alloc] initWithApp:kPHEventRequestTestToken secret:
                kPHEventRequestTestSecret event:theTestEvent], @"Cannot create event "
                "request!");
}

- (void)testEventRequestProperties
{
    NSDictionary *theProperties =
    @{
        kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1,
        kPHTestEventPropertyKey2 : @[kPHTestEventPropertyValue2],
        kPHTestEventPropertyKey3 : @(NO),
        kPHTestEventPropertyKey4 : kPHTestEventPropertyValue3
    };
    PHEvent *theTestEvent = [PHEvent eventWithProperties:theProperties];
    XCTAssertNotNil(theTestEvent, @"Cannot create event necessary for the test!");

    PHEventRequest *theTestRequest = [PHEventRequest requestForApp:kPHEventRequestTestToken secret:
                kPHEventRequestTestSecret event:theTestEvent];

    XCTAssertNotNil(theTestRequest, @"Cannot create event request!");
    XCTAssertEqualObjects(PH_URL(/v4/publisher/event/), theTestRequest.urlPath, @"Request end-point "
                "doesn't match the expected one!");
    XCTAssertEqual(PHRequestHTTPPost, theTestRequest.HTTPMethod, @"Request method doesn't match the"
                " expected one!");

    NSURL *theRequestURL = [self URLForRequest:theTestRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain final request URL!");
    
    NSDictionary *theQueryComponents = [theRequestURL queryComponents];
    XCTAssertNotNil(theQueryComponents, @"Request query should not be nil!");

    NSString *theEventsJSON = theQueryComponents[@"data"];
    XCTAssertNotNil(theEventsJSON, @"Missed required parameters!");

    
    NSData *theEventsJSONData = [theEventsJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *theError = nil;
    NSArray *theDecodedEvents = theEventsJSONData ? [NSJSONSerialization JSONObjectWithData:theEventsJSONData options:0 error:&theError] : nil;
    
    XCTAssertNotNil(theDecodedEvents, @"Cannot decode events JSON to array representation!");
    XCTAssertTrue([theDecodedEvents count] > 0, @"Events array should contain one event!");
    
    NSDictionary *theEventDictionary = theDecodedEvents[0];
    XCTAssertNotNil(theEventDictionary, @"Events dictionary should contain the event that was passed"
                " to request initializer!");
    XCTAssertTrue(0 < [theEventDictionary[@"ts"] integerValue], @"Unexpected timestamp of the "
                "event!");
    XCTAssertEqualObjects(theProperties, theEventDictionary[@"event"], @"Event's properties don't "
                "match the ones that were passed to event initializer!");

    // Verify events signature
    NSString *theEventsSignature = theQueryComponents[@"data_sig"];
    XCTAssertNotNil(theEventsSignature, @"Missed events signature!");

    NSString *theExpectedSignature = [[PHAPIRequest class] v4SignatureWithMessage:theEventsJSON
                signatureKey:theTestRequest.secret];
    XCTAssertEqualObjects(theExpectedSignature, theEventsSignature, @"Event signature doesn't match "
                "the expected one!");
}

- (void)testNoIDFAParameterWithOptedInUser
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];

    NSDictionary *theProperties = @{kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1};
    PHEvent *theTestEvent = [PHEvent eventWithProperties:theProperties];
    XCTAssertNotNil(theTestEvent, @"Cannot create event necessary for the test!");
    
    PHEventRequest *theTestRequest = [[PHEventRequest alloc] initWithApp:kPHEventRequestTestToken
                secret:kPHEventRequestTestSecret event:theTestEvent];
    
    NSString *theRequestURL = [[self URLForRequest:theTestRequest] absoluteString];
    NSDictionary *theSignedParameters = [theTestRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    XCTAssertNil(theIDFA, @"IDFA should not be included in custom event tracking requests!");
    XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"IDFA should not be included "
                "in custom event tracking requests!");

    // Restore opt out status
    [PHAPIRequest setOptOutStatus:theOptOutFlag];
}

@end
