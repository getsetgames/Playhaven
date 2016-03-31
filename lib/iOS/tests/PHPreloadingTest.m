//
//  PHPreloadingTest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/23/15.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "PHPreloadingObject.h"
#import "PHBeaconManager.h"
#import "PHBeaconObject.h"
#import "PHPreloader.h"
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"

#define TEST_VIDEO_AD @"http://cdn.liverail.com/adasset4/1331/229/331/lo.mp4"
#define TEST_VIDEO_AD_2 @"http://cdn.liverail.com/adasset4/1331/229/7969/me.flv"

@interface PHPreloadingTest : XCTestCase {
    PHPreloader *_preloader;
    id<OHHTTPStubsDescriptor> _preloaderStub;
    NSString *_sampleResponse;
    NSDictionary *_response;
    XCTestExpectation *_expectation1;
    XCTestExpectation *_expectation2;
    XCTestExpectation *_expectation3;
    PHPreloadingObject *_preloadingObject1;
    PHPreloadingObject *_preloadingObject2;
    PHPreloadingObject *_preloadingObject3;
    PHPreloadingObject *_preloadingObject4;
    PHPreloadingObject *_preloadingObject5;
}

@end

@implementation PHPreloadingTest

- (void)setUp {
    _preloaderStub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithFileAtPath:OHPathForFile(@"aWon-a.mp4", self.class)
                                                 statusCode:200
                                                    headers:@{@"Content-Type":@"video/mp4"}]
                requestTime:0.f
                responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    _preloaderStub.name = @"Image stub";
    
    _sampleResponse = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:self.class]
                                                         URLForResource:@"cacheCreativeResponse"
                                                         withExtension:@"json"]
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];
    
    NSData *jsonData = [_sampleResponse dataUsingEncoding:NSUTF8StringEncoding];
    id parserObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    _response = (NSDictionary *)parserObject;
    
    _preloader = [PHPreloader sharedPreloader];
    [_preloader clear];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishPreloading:)
                                                 name:PHDidFinishPreloadingNotification
                                               object:nil];
    
}

- (void)testPreloadingObjectDownload {
    _expectation1 = [self expectationWithDescription:@"Download Expectation"];
    
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSString *url = [[cache objectAtIndex:0] objectForKey:@"url"];
    NSInteger *creativeId = [[[cache objectAtIndex:0] objectForKey:@"creative_id"] intValue];

    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
    
    _preloadingObject1 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:creativeId];
    XCTAssertNoThrow([_preloadingObject1 start], @"should start downloading with no issues.");
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        XCTAssertEqual([[PHPreloader newSavedFilesArray] count], 1);
        [_preloader clear];
        XCTAssertEqual([[PHPreloader newSavedFilesArray] count], 0);
    }];
}

- (void)testPreloaderQueueing {
    _expectation2 = [self expectationWithDescription:@"Queue Expectation"];
    
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSString *url = [[cache objectAtIndex:0] objectForKey:@"url"];
    
    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
    
    
    _preloadingObject2 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:5];
    // Same ID, shouldn't be added
    _preloadingObject3 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:5];
    _preloadingObject4 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:6];
    _preloadingObject5 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:6];

    [_preloader startPreloading:_preloadingObject2];
    XCTAssertEqual((int)_preloader.queue.count, 1, @"There should be 1 item in the queue");
    [_preloader startPreloading:_preloadingObject3];
    XCTAssertEqual((int)_preloader.queue.count, 1, @"There should be 1 item in the queue");
    [_preloader startPreloading:_preloadingObject4];
    XCTAssertEqual((int)_preloader.queue.count, 2, @"There should be 2 item in the queue");
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        XCTAssertEqual([[PHPreloader newSavedFilesArray] count], 2);
        
        [_preloader startPreloading:_preloadingObject5];
        XCTAssertEqual((int)_preloader.queue.count, 0, @"There should be 0 items in the queue");
    }];
}

- (void)tearDown {
    [_preloader clear];
    _preloaderStub = nil;
}

#pragma mark -
#pragma mark PHPreloadingObject notification

- (void)didFinishPreloading:(NSNotification *)notification {
    if ([notification.object isEqual:_preloadingObject1]) {
        [_expectation1 fulfill];
    }
    if (([notification.object isEqual:_preloadingObject2] ||
         [notification.object isEqual:_preloadingObject3] ||
         [notification.object isEqual:_preloadingObject4]) &&
        _preloader.queue.count == 0 &&
        [[PHPreloader newSavedFilesArray] count] == 2) {
        
        [_expectation2 fulfill];
    }
}

@end