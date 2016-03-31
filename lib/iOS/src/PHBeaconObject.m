//
//  PHBeaconObject.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/18/15.
//
//

#import "PHBeaconObject.h"
#import "PHConstants.h"

@interface PHBeaconObject() {
    NSMutableDictionary *_beacons;
}

@end

@implementation PHBeaconObject

- (void)addBeacons:(NSDictionary *)beacons {
    for (NSString *key in beacons) {
        [self addBeaconFromString:key withURLs:[beacons objectForKey:key]];
    }
}

- (void)addBeacon:(PHBeacon)beacon withURLs:(NSArray *)urls {
    if (!_beacons) {
        _beacons = [[NSMutableDictionary alloc] init];
    }
    if ([_beacons objectForKey:[NSNumber numberWithInt:beacon]]) {
        [_beacons setObject:[[_beacons objectForKey:[NSNumber numberWithInt:beacon]] arrayByAddingObjectsFromArray:urls]
                     forKey:[NSNumber numberWithInt:beacon]];
    } else {
        [_beacons setObject:urls forKey:[NSNumber numberWithInt:beacon]];
    }
}

- (void)addBeaconFromString:(NSString *)beaconName withURLs:(NSArray *)urls {
    PHBeacon beacon = PHBeaconNone;
    
    if ([beaconName isEqualToString:@"preload_start"])      beacon = PHDidStartPreloading;
    if ([beaconName isEqualToString:@"preload_complete"])   beacon = PHDidPreload;
    if ([beaconName isEqualToString:@"preload_canceled"])   beacon = PHDidFailToPreload;
    
    if (beacon != PHBeaconNone) {
        [self addBeacon:beacon withURLs:urls];
    }
}

- (NSArray *)getBeaconURLs:(PHBeacon)beacon {
    return [_beacons objectForKey:[NSNumber numberWithInt:beacon]];
}

+ (NSString *)getVariableFromURLString:(NSString *)s openString:(NSString *)openString closeString:(NSString *)closeString openOffset:(NSInteger)offset {
    if ([s rangeOfString:openString].location == NSNotFound || [s rangeOfString:closeString].location == NSNotFound) {
        return nil;
    }
    NSInteger left, right;
    NSString *foundData;
    NSScanner *scanner = [NSScanner scannerWithString:s];
    [scanner scanUpToString:openString intoString:nil];
    left = [scanner scanLocation];
    [scanner setScanLocation:left + offset];
    [scanner scanUpToString:closeString intoString: nil];
    right = [scanner scanLocation] + 1;
    left += offset;
    foundData = [s substringWithRange: NSMakeRange(left, (right - left) - 1)];
    return foundData;
}

- (NSArray *)newArrayOfSubstitutedValuesForBeacon:(PHBeacon)beacon withData:(NSDictionary *)data {
    NSMutableArray *subArray = [[NSMutableArray alloc] init];
    NSArray *beaconValue = [self getBeaconURLs:beacon];
    
    for (NSString *urlString in beaconValue) {
        NSString *urlStringWithReplacement = urlString;
        NSString *variable = [PHBeaconObject getVariableFromURLString:urlString
                                                           openString:PH_URL_VAR_OPEN
                                                          closeString:PH_URL_VAR_CLOSE
                                                           openOffset:2];
        
        id variableValue = [data objectForKey:variable];
        if (variableValue) {
            if ([variableValue isKindOfClass:[NSString class]] || [variableValue isKindOfClass:[NSNumber class]]) {
                NSString *stringValue = ([variableValue isKindOfClass:[NSNumber class]]) ? [variableValue stringValue] : variableValue;
                urlStringWithReplacement = [urlString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", variable]
                                                                                withString:stringValue];
            }
        }
        [subArray addObject:urlStringWithReplacement];
    }
    
    return subArray;
    
}

@end
