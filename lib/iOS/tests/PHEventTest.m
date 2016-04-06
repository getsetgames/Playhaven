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

 PHEventTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/26/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PlayHavenSDK.h"

static NSString *const kPHTestEventPropertyKey1 = @"EventPropertyKey1";
static NSString *const kPHTestEventPropertyKey2 = @"EventPropertyKey2";
static NSString *const kPHTestEventPropertyKey3 = @"EventPropertyKey3";
static NSString *const kPHTestEventPropertyKey4 = @"EventPropertyKey4";
static NSString *const kPHTestEventPropertyKey5 = @"EventPropertyKey5";
static NSString *const kPHTestEventPropertyKey6 = @"EventPropertyKey6";
static NSString *const kPHTestEventPropertyKey7 = @"EventPropertyKey7";
static NSString *const kPHTestEventPropertyKey8 = @"EventPropertyKey8";
static NSString *const kPHTestEventPropertyKey9 = @"EventPropertyKey9";

static NSString *const kPHTestEventPropertyValue1 = @"EventPropertyValue1";
static NSString *const kPHTestEventPropertyValue2 = @"EventPropertyValue2";
static NSString *const kPHTestEventPropertyValue3 = @"!@#$%^&*(+_)(GVLSAJUCBAIU";

@interface PHEventTest : XCTestCase
@end

@implementation PHEventTest

- (void)testCreationWithClassMethod
{
    NSDictionary *theProperties = @{kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1};
    
    XCTAssertNil([PHEvent eventWithProperties:nil], @"Event object should not be created with nil "
                "properties dictionary!");
    XCTAssertNotNil([PHEvent eventWithProperties:theProperties], @"Cannot create event object!");

    // Create properties dictionary that cannot be converted into JSON
    theProperties = @{kPHTestEventPropertyKey1 : [kPHTestEventPropertyValue1 dataUsingEncoding:
                NSUTF8StringEncoding]};
    XCTAssertNil([PHEvent eventWithProperties:theProperties], @"Event object "
                "should not be created with properties that cannot be converted into JSON!");

    // Create properties dictionary that cannot be converted into JSON
    theProperties = @{kPHTestEventPropertyKey1 : [NSDate date]};
    XCTAssertNil([PHEvent eventWithProperties:theProperties], @"Event object should not be created "
                "with properties that cannot be converted into JSON!");

    // Create properties dictionary that cannot be converted into JSON
    theProperties = @{kPHTestEventPropertyKey1 : [NSSet setWithObject:kPHTestEventPropertyValue1]};
    XCTAssertNil([PHEvent eventWithProperties:theProperties], @"Event object should not be created "
                "with properties that cannot be converted into JSON!");
}

- (void)testCreationWithInitializer
{
    NSDictionary *theProperties = @{kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1};
    
    XCTAssertNil([[PHEvent alloc] initWithProperties:nil], @"Event object should not "
                "be created with nil properties dictionary!");
    XCTAssertNotNil([[PHEvent alloc] initWithProperties:theProperties], @"Cannot "
                "create event object!");
}

- (void)testEventProperties
{
    NSUInteger theTestIntegerValue = 123;
    float theTestFloatValue = 123.4567f;
    BOOL theTestBoolValue = YES;

    NSDictionary *theProperties =
    @{
        kPHTestEventPropertyKey1 : kPHTestEventPropertyValue1,
        kPHTestEventPropertyKey2 : @{kPHTestEventPropertyKey3 : kPHTestEventPropertyValue2},
        kPHTestEventPropertyKey4 : @[kPHTestEventPropertyValue1, kPHTestEventPropertyValue2],
        kPHTestEventPropertyKey5 : @(theTestIntegerValue),
        kPHTestEventPropertyKey6 : [NSDecimalNumber numberWithFloat:theTestFloatValue],
        kPHTestEventPropertyKey7 : [NSNull null],
        kPHTestEventPropertyKey8 : @(theTestBoolValue),
        kPHTestEventPropertyKey9 : kPHTestEventPropertyValue3
    };

    PHEvent *theTestEvent = [PHEvent eventWithProperties:theProperties];
    XCTAssertNotNil(theTestEvent, @"Cannot create event object!");
    XCTAssertEqualObjects(theProperties, theTestEvent.properties, @"Event's properties don't match "
                "the ones passed to the ititializer!");
    
    NSString *theJSONRepresentation = theTestEvent.JSONRepresentation;
    XCTAssertNotNil(theJSONRepresentation, @"JSON representation of the event object should not be "
                "nil");
    
    NSData *jsonData = [theJSONRepresentation dataUsingEncoding:NSUTF8StringEncoding];
    NSError *theError = nil;
    NSDictionary *theDecodedEvent = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&theError] : nil;
    
    XCTAssertNotNil(theDecodedEvent, @"Cannot decode the event JSON: %@", theError);
    XCTAssertTrue((NSUInteger)[[NSDate date] timeIntervalSince1970] >= [theDecodedEvent[@"ts"]
                integerValue], @"Unexpected time stamp of the event!");
    XCTAssertEqualObjects(theProperties, theDecodedEvent[@"event"], @"Event's properties don't match "
                "the ones passed to the initializer!");
}

@end
