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

 PHPublisherMetadataRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PHPublisherMetadataRequest.h"
#import "PHConstants.h"
#import "SenTestCase+PHAPIRequestSupport.h"

static NSString *const kPHTestToken  = @"PUBLISHER_TOKEN";
static NSString *const kPHTestSecret = @"PUBLISHER_SECRET";
static NSString *const kPHTestPlacement = @"test_placement";

@interface PHPublisherMetadataRequestTest : XCTestCase
@end

@implementation PHPublisherMetadataRequestTest

- (void)testInstance
{
    PHPublisherMetadataRequest *request = [PHPublisherMetadataRequest requestForApp:@"" secret:@"" placement:@"" delegate:self];
    XCTAssertNotNil(request, @"expected request instance, got nil");
}
- (void)testRequestParameters
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherMetadataRequest *request = [PHPublisherMetadataRequest requestForApp:token secret:secret];

    NSURL *theRequestURL = [self URLForRequest:request];
    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [theRequestURL absoluteString];

//#define PH_USE_MAC_ADDRESS 1
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

- (void)testIDFAParameterWithOptedInUser
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];
    
    PHPublisherMetadataRequest *theRequest = [PHPublisherMetadataRequest requestForApp:kPHTestToken
                secret:kPHTestSecret placement:kPHTestPlacement delegate:nil];
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

- (void)testIDFAParameterWithOptedOutUser
{
    BOOL theOptOutFlag = [PHAPIRequest optOutStatus];
    
    // User is opted in
    [PHAPIRequest setOptOutStatus:YES];
    
    PHPublisherMetadataRequest *theRequest = [PHPublisherMetadataRequest requestForApp:kPHTestToken
                secret:kPHTestSecret placement:kPHTestPlacement delegate:nil];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    XCTAssertNil(theIDFA, @"IDFA should not be sent for opted out users!");
    XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                "not be sent for opted out users!");
    
    // Restore opt out status
    [PHAPIRequest setOptOutStatus:theOptOutFlag];
}

@end
