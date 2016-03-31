//
//  PHMoviePlayerViewControllerTest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 11/13/15.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "PHPreloader.h"
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"
#import "PHMoviePlayerViewController.h"

@interface PHMoviePlayerViewControllerTest : XCTestCase {
    PHPreloader *_preloader;
    id<OHHTTPStubsDescriptor> _preloaderStub;
    XCTestExpectation *_expectation1;
    XCTestExpectation *_expectation2;
    NSDictionary *_response;
    PHPreloadingObject *_preloadingObject1;
    PHPreloadingObject *_preloadingObject2;
    PHMoviePlayerViewController *moviePlayerController1;
    PHMoviePlayerViewController *moviePlayerController2;
    NSString *_sampleResponse;
}

@end

@implementation PHMoviePlayerViewControllerTest

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
    _preloaderStub.name = @"Video stub";
    
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

- (void)testMoviePlayer {
    _expectation1 = [self expectationWithDescription:@"Download Expectation"];
    
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSString *url = [[cache objectAtIndex:0] objectForKey:@"url"];
    NSInteger *creativeId = 5;
    
    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
    
    _preloadingObject1 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:creativeId];
    XCTAssertNoThrow([_preloadingObject1 start], @"should start downloading with no issues.");
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    _expectation1 = [self expectationWithDescription:@"Play Expectation"];
    
    NSString *filePath = [PHPreloader getFullPathFromCreativeId:creativeId];
    NSURL *contentURL = (filePath) ? [NSURL fileURLWithPath:filePath] : nil;
    XCTAssertNotNil(contentURL, @"The content URL should be valid");
    
    moviePlayerController1 = [[PHMoviePlayerViewController alloc] initWithContentURL:contentURL];
    
    [moviePlayerController1.moviePlayer play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleVideoComplete:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [moviePlayerController1.moviePlayer stop];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMoviePlayerContentDownload {
    _expectation2 = [self expectationWithDescription:@"Movie Player Download Expectation"];
    
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSString *url = [[cache objectAtIndex:0] objectForKey:@"url"];
    NSInteger *creativeId = 6;
    
    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
    
    _preloadingObject2 = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:[NSURL URLWithString:url] creativeId:creativeId];
    
    moviePlayerController2 = [[PHMoviePlayerViewController alloc] init];
    [moviePlayerController2 loadRemoteFile:_preloadingObject2];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        [moviePlayerController2.moviePlayer play];
    }];

    [moviePlayerController2.moviePlayer stop];

}

- (void)tearDown {
    [_preloader clear];
}

#pragma mark -
#pragma mark PHPreloadingObject notification

- (void)didFinishPreloading:(NSNotification *)notification {
    if ([notification.object isEqual:_preloadingObject1] && _preloader.queue.count == 0) {
        [_expectation1 fulfill];

    }
    
    if ([notification.object isEqual:_preloadingObject2] && _preloader.queue.count == 0) {
        [_expectation2 fulfill];
    }
}

- (void)handleVideoComplete:(NSNotification *)notification {
    [_expectation1 fulfill];
}

@end