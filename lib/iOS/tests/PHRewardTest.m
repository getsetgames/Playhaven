//
//  PHRewardTest.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 2/4/16.
//
//

#import <XCTest/XCTest.h>
#import "PHAPIRequest.h"
#import "PHAPIRequest+Private.h"
#import "PHConnectionManager.h"
#import "PHPublisherContentRequest.h"
#import "PHContent.h"
#import "PHContentView.h"

@interface PHAPIRequest (Private) <PHConnectionManagerDelegate>
+ (NSMutableSet *)allNonces;
@end

@interface PHRewardTest : XCTestCase {
    NSDictionary *rewardData;
    PHContentView *_contentView;
}

@end

@implementation PHRewardTest

- (void)setUp {
    [super setUp];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resource = [bundle pathForResource:@"rewardData" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:resource];
    rewardData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    PHContent *_content = [[PHContent alloc] init];
    
    _contentView = [[PHContentView alloc] initWithContent:_content];
    [_contentView redirectRequest:@"ph://rewards" toTarget:self action:@selector(checkReward:)];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRewardValidation {
    NSString *correctNonce = [rewardData objectForKey:@"nonce"];
    [[PHAPIRequest allNonces] addObject:correctNonce];

    NSURLRequest *rewardRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"ph://rewards"]];
    BOOL result = [_contentView webView:nil shouldStartLoadWithRequest:rewardRequest navigationType:UIWebViewNavigationTypeLinkClicked];
    XCTAssertFalse(result, @"should not open ph://rewards in webview!");
}

- (void)checkReward:(NSDictionary *)parameters {
    NSLog(@"got callback");
}


@end
