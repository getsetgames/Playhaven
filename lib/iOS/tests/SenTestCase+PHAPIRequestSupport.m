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

 SenTestCase+PHAPIRequestSupport.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 10/15/13
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "SenTestCase+PHAPIRequestSupport.h"
#import "PlayHavenSDK.h"
#import "PHAPIRequest+Private.h"

@implementation XCTestCase (PHAPIRequestSupport)

- (NSURL *)URLForRequest:(PHAPIRequest *)aRequest
{
    __block BOOL theURLConstructed = NO;
    __block NSURL *theRequestURL = nil;
    [aRequest constructRequestURLWithCompletionHandler:
    ^(NSURL *inURL)
    {
        theURLConstructed = YES;
        theRequestURL = inURL;
    }];

    NSDate *theStartDate = [NSDate date];
    const NSTimeInterval kCompletionTimeout = 5;
    while (!theURLConstructed &&  [[NSDate date] timeIntervalSinceDate:theStartDate] <
                kCompletionTimeout)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate
                    dateWithTimeIntervalSinceNow:0.1]];
    }
    
    return theRequestURL;
}

@end
