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

 PHEvent.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/25/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHEvent.h"
#import "PHConstants.h"

static NSString *const kPHEventTimestampKey = @"ts";
static NSString *const kPHEventPropertiesKey = @"event";

@interface PHEvent ()
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval timestamp;
@property (nonatomic, strong, readonly) NSDictionary *eventDictionary;
@end

@implementation PHEvent
@synthesize eventDictionary = _eventDictionary;

+ (id)eventWithProperties:(NSDictionary *)aProperties
{
    return [[self alloc] initWithProperties:aProperties];
}

- (instancetype)initWithProperties:(NSDictionary *)aProperties
{
    if (nil == aProperties || ![[self class] isPropertiesValid:aProperties])
    {
        PH_LOG(@"%s[ERROR] Cannot create event object with the given properties: %@",
                    __PRETTY_FUNCTION__, aProperties);

        return nil;
    }
    
    self = [super init];
    if (nil != self)
    {
        _eventDictionary = @{kPHEventTimestampKey : @((NSInteger)[[NSDate date]
                    timeIntervalSince1970]), kPHEventPropertiesKey : aProperties};
    }
    
    return self;
}

- (NSString *)properties
{
    return self.eventDictionary[kPHEventPropertiesKey];
}

- (NSString *)JSONRepresentation
{
    NSError *theError = nil;
    NSString *theJSONRepresentation = [[self class] JSONStringFromDictionary:self.eventDictionary
                error:&theError];
    
    if (nil == theJSONRepresentation)
    {
        PH_LOG(@"%s[ERROR] Cannot get JSON representation of the event: error - %@;\nevent - %@",
                    __PRETTY_FUNCTION__, theError, self.eventDictionary);
        return nil;
    }
    
    return theJSONRepresentation;
}

#pragma mark - Private

+ (BOOL)isPropertiesValid:(NSDictionary *)aProperties
{
    NSError *theError = nil;
    
    if (nil != aProperties && nil == [[self class] JSONStringFromDictionary:aProperties error:
                &theError])
    {
        PH_LOG(@"%s[ERROR] aProperties object cannot be converted into JSON string: %@",
                    __PRETTY_FUNCTION__, theError);
        return NO;
    }
    
    return YES;
}

+ (NSString *)JSONStringFromDictionary:(NSDictionary *)aDictionary error:(NSError **)aoError
{
    if (NULL != aoError)
    {
        *aoError = nil;
    }
    
    if (nil == aDictionary)
    {
        return nil;
    }
    
    NSData *theJSONData = aDictionary ? [NSJSONSerialization dataWithJSONObject:aDictionary options:0 error:aoError] : nil;
    NSString *theJSONString = [[NSString alloc] initWithData:theJSONData encoding:NSUTF8StringEncoding];

    return theJSONString;
}

@end
