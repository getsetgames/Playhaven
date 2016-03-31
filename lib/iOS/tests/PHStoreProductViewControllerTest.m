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

 PHStoreProductViewControllerTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 10/10/13
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PlayHavenSDK.h"

@interface PHStoreProductViewControllerTest : XCTestCase
@end

@implementation PHStoreProductViewControllerTest

- (void)testSingleton
{
    PHStoreProductViewController *theSharedInstance = [PHStoreProductViewController sharedInstance];
    XCTAssertNotNil(theSharedInstance, @"Cannot access singleton instance!");
    
    XCTAssertEqualObjects(theSharedInstance, [PHStoreProductViewController new], @"");
}

- (void)testStore
{
    PHStoreProductViewController *theSharedInstance = [PHStoreProductViewController sharedInstance];
    XCTAssertFalse([theSharedInstance showProductId:nil], @"In-app store should not be shown for nil"
                "product!");
}

@end
