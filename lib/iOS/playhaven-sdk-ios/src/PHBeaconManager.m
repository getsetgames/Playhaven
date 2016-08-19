//
//  PHBeaconManager.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/18/15.
//
//

#import "PHBeaconManager.h"
#import "PHURLLoader.h"

@implementation PHBeaconManager

- (id)initWithBeaconObject:(PHBeaconObject *)beaconObject {
    self = [super init];
    if (self){
        self.beaconObject = beaconObject;
    }
    return self;
}

- (void)pingBeacons:(NSArray *)urls {
    for (NSString *urlString in urls) {
        PHURLLoader *loader = [[PHURLLoader alloc] init];
        loader.opensFinalURLOnDevice = NO;
        loader.targetURL = [NSURL URLWithString:urlString];
        [loader open];
    }
}

- (void)pingBeaconForEvent:(PHBeacon)beacon withData:(NSDictionary *)data {
    if ([self.beaconObject getBeaconURLs:beacon]) {
        if (data) {
            NSArray *subArray = [self.beaconObject newArrayOfSubstitutedValuesForBeacon:beacon withData:data];
            [self pingBeacons:subArray];
        } else {
            [self pingBeacons:[self.beaconObject getBeaconURLs:beacon]];
        }
    }
}

@end
