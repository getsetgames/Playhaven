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

 PHAdRequestTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 4/17/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PHConstants.h"
#import "PHAdRequest.h"
#import "SenTestCase+PHAPIRequestSupport.h"

#define PUBLISHER_TOKEN @"PUBLISHER_TOKEN"
#define PUBLISHER_SECRET @"PUBLISHER_SECRET"

@interface PHAdRequestTest : XCTestCase
@end

@implementation PHAdRequestTest

- (void)testIDFAParameterWithOptedInUser
{
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];
    
    PHAdRequest *theRequest = [PHAdRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
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
}

- (void)testIDFAParameterWithOptedOutUser
{
    // User is opted out
    [PHAPIRequest setOptOutStatus:YES];
    
    PHAdRequest *theRequest = [PHAdRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    XCTAssertNil(theIDFA, @"IDFA should not be sent for opted out users!");
    XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                "not be sent for opted out users!");
    
    // Revert opt-out status
    [PHAPIRequest setOptOutStatus:NO];
}

@end
