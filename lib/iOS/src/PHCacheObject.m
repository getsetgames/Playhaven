//
//  PHCacheObject.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/2/15.
//
//

#import "PHCacheObject.h"

@implementation PHCacheObject

- (id)initWithURLString:(NSURL *)url creativeId:(NSInteger)creativeId {
    self = [super init];
    if (self != nil) {
        self.creativeId = creativeId;
        if ([url.absoluteString characterAtIndex:0] == [@"/" characterAtIndex:0]) {
            self.url = [NSURL URLWithString:[@"https:" stringByAppendingString:url.absoluteString]];
        } else {
            self.url = url;
        }
        self.fileName = [NSString stringWithFormat:@"%li-%@", (long)creativeId, [[self.url absoluteString] lastPathComponent]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.creativeId forKey:@"creativeId"];
    [coder encodeObject:self.fileName forKey:@"fileName"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.creativeId = [coder decodeIntegerForKey:@"creativeId"];
        self.fileName = [coder decodeObjectForKey:@"fileName"];
    }
    return self;
}

@end
