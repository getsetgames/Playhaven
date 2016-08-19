//
//  PHBeaconTest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/18/15.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "PHBeaconObject.h"
#import "PHBeaconManager.h"
#import "PHConstants.h"
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"
#import "PHPublisherOpenRequest.h"

@interface PHBeaconTest : XCTestCase {
    NSError *_error;
    NSString *_sampleResponse;
    NSDictionary *_response;
}

@end

@implementation PHBeaconTest

- (void)setUp {
    _sampleResponse = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:self.class]
                                                         URLForResource:@"cacheCreativeResponse"
                                                         withExtension:@"json"]
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];
    
    NSData *jsonData = [_sampleResponse dataUsingEncoding:NSUTF8StringEncoding];
    id parserObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    _response = (NSDictionary *)parserObject;
}

- (void)testBeaconObject {
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSDictionary *beacons = [[cache objectAtIndex:0] objectForKey:@"beacons"];
    
    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    [beaconObject addBeacons:beacons];
    
    XCTAssertEqualObjects([beaconObject getBeaconURLs:PHDidStartPreloading],
                          [beacons objectForKey:@"preload_start"],
                          @"URLs returned from BeaconObject should equal the value passed in for that beacon");
    
    XCTAssertNotEqual([beaconObject getBeaconURLs:PHDidCancelPreload],
                      [beacons objectForKey:@"preload_start"],
                      @"URLs returned from BeaconObject should only equal the value passed in for that beacon");
}

- (void)testBeaconManager {
    NSDictionary *responseObject = [_response objectForKey:@"response"];
    NSArray *cache = [responseObject objectForKey:@"cache"];
    NSDictionary *beacons = [[cache objectAtIndex:0] objectForKey:@"beacons"];
    
    PHBeaconObject *beaconObject = [[PHBeaconObject alloc] init];
    [beaconObject addBeacons:beacons];
    PHBeaconManager *beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
    
    XCTAssertNoThrow([beaconManager pingBeaconForEvent:PHDidPreload withData:nil], @"Should ping beacon");
    XCTAssertNoThrow([beaconManager pingBeaconForEvent:PHDidFailToPreload withData:nil], @"Should ping beacon");
    XCTAssertNoThrow([beaconManager pingBeaconForEvent:PHDidCancelPreload withData:nil], @"Should work, even if event doesn't exist. It just won't ping anything");
    
}

@end