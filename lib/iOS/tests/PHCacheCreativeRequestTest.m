//
//  PHCacheCreativeRequestTest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/13/15.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "PHCacheCreativeRequest.h"
#import "PHPreloader.h"
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"

@interface PHCacheCreativeRequestTest : XCTestCase <PHCacheCreativeRequestDelegate> {
    id<OHHTTPStubsDescriptor> _cacheCreativeStub;
    PHPreloader *_preloader;
    XCTestExpectation *_expectation1;
}

@end

@implementation PHCacheCreativeRequestTest

- (void)setUp {
    _preloader = [PHPreloader sharedPreloader];
    [_preloader clear];
    
}

- (void)testCacheCreativeRequest {
    _expectation1 = [self expectationWithDescription:@"Cache Creative Expectation"];
    PHCacheCreativeRequest *request = [[PHCacheCreativeRequest alloc] initWithApp:@"zombie1"
                                                                           secret:@"haven1"
                                                                         delegate:self];
    
    [request send];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        XCTAssertNotNil(request.preloader, @"There should be a preloader");
    }];
}

#pragma mark -
#pragma mark PHCacheCreativeRequest delegate methods

- (void)cacheRequest:(id)sender request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData {
    [_expectation1 fulfill];
}

@end