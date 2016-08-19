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

 NSString+QueryComponentsTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/28/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "NSObject+QueryComponents.h"

static NSString *const kPHTestString1 =
            @"±!@#$%^&*().,$-'_:;<>/[]|{}~\\WERTYUI +§¡™£¢∞§¶•ªº–≠œ∑´®†¥¨ˆøπ“åß∂ƒ©˙∆˚¬…`Ω≈ç√∫˜µ";
static NSString *const kPHTestString2 =
            @"{\n\t\"type\":\"buttonClicked\",\t\"data\":{\"buttonTitle\":\"Start\"}}";

// Expected values match the ones obtained by means of http://www.url-encode-decode.com and
// http://www.freeformatter.com/url-encoder.html
static NSString *const kPHDecodedTestString1 =
            @"%C2%B1%21%40%23%24%25%5E%26*%28%29.%2C%24-%27_%3A%3B%3C%3E%2F%5B%5D%7C%7B%7D%7E%5C"
            "WERTYUI+%2B%C2%A7%C2%A1%E2%84%A2%C2%A3%C2%A2%E2%88%9E%C2%A7%C2%B6%E2%80%A2%C2%AA%C2%BA"
            "%E2%80%93%E2%89%A0%C5%93%E2%88%91%C2%B4%C2%AE%E2%80%A0%C2%A5%C2%A8%CB%86%C3%B8%CF%80"
            "%E2%80%9C%C3%A5%C3%9F%E2%88%82%C6%92%C2%A9%CB%99%E2%88%86%CB%9A%C2%AC%E2%80%A6%60%CE"
            "%A9%E2%89%88%C3%A7%E2%88%9A%E2%88%AB%CB%9C%C2%B5";
static NSString *const kPHDecodedTestString2 =
            @"%7B%0A%09%22type%22%3A%22buttonClicked%22%2C%09%22data%22%3A%7B%22buttonTitle%22%3A"
            "%22Start%22%7D%7D";

@interface NSString_QueryComponentsTest : XCTestCase
@end

@implementation NSString_QueryComponentsTest

- (void)testURLEncodingDecoding
{
    XCTAssertEqualObjects(kPHDecodedTestString1, [kPHTestString1 stringByEncodingURLFormat], @"The "
                "decoded string doesn't match the expected one!");
    XCTAssertEqualObjects(kPHTestString1, [[kPHTestString1 stringByEncodingURLFormat]
                stringByDecodingURLFormat], @"The decoded string should be equal to the original "
                "string!");

    XCTAssertEqualObjects(kPHDecodedTestString2, [kPHTestString2 stringByEncodingURLFormat], @"The "
                "decoded string doesn't match the expected one!");
    XCTAssertEqualObjects(kPHTestString2, [[kPHTestString2 stringByEncodingURLFormat]
                stringByDecodingURLFormat], @"The decoded string should be equal to the original "
                "string!");
}

@end
