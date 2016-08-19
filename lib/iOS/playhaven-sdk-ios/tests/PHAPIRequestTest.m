/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013-2014 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHAPIRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <XCTest/XCTest.h>
#import "PHAPIRequest.h"
#import "PHConstants.h"
#import "PHStringUtil.h"
#import "PHPublisherOpenRequest.h"
#import "PHAPIRequest+Private.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "PHConnectionManager.h"

#define PUBLISHER_TOKEN @"PUBLISHER_TOKEN"
#define PUBLISHER_SECRET @"PUBLISHER_SECRET"

#define HASH_STRING  @"DEVICE_ID:PUBLISHER_TOKEN:PUBLISHER_SECRET:NONCE"
#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"

static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";

static NSString *const kPHErrorDescription = @"this is awesome!";

@interface PHAPIRequest (Private) <PHConnectionManagerDelegate>
+ (NSMutableSet *)allRequests;
+ (void)setSession:(NSString *)session;
- (void)processRequestResponse:(NSDictionary *)response;
@end

@interface PHAPIRequestTest : XCTestCase <PHAPIRequestDelegate>
@property (nonatomic, getter=isRequestSucceeded) BOOL requestSucceeded;
@property (nonatomic, getter=isRequestFailed) BOOL requestFailed;
@property (nonatomic, strong) NSError *reportedError;
@end

@interface PHAPIRequestResponseTest : XCTestCase <PHAPIRequestDelegate> {
    PHAPIRequest *_request;
    BOOL _didProcess;
}
@end
@interface PHAPIRequestErrorTest : XCTestCase <PHAPIRequestDelegate> {
    PHAPIRequest *_request;
    BOOL _didProcess;
}
@end
@interface PHAPIRequestByHashCodeTest : XCTestCase @end

@implementation PHAPIRequestTest

- (void)setUp
{
    [super setUp];

    // Cancel request to remove it from the cache
    [[PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET] cancel];
    
    self.requestSucceeded = NO;
    self.requestFailed = NO;
    self.reportedError = nil;
}

- (void)testSignatureHash
{
    NSString *signatureHash = [PHAPIRequest base64SignatureWithString:HASH_STRING];
    XCTAssertTrue([EXPECTED_HASH isEqualToString:signatureHash],
                 @"Hash mismatch. Expected %@ got %@",EXPECTED_HASH,signatureHash);
}

- (void)testResponseDigestVerification
{
    /*
     For this test expected digest hashes were generated using pyton's hmac library.
     */
    NSString *responseDigest, *expectedDigest;

    // Digest with nonce
    responseDigest = [PHAPIRequest expectedSignatureValueForResponse:@"response body" nonce:@"nonce" secret:PUBLISHER_SECRET];
    expectedDigest = @"rt3JHGReRAaol-xPVildr6Ev9fU=";
    XCTAssertTrue([responseDigest isEqualToString:expectedDigest], @"Digest mismatch. Expected %@ got %@", expectedDigest, responseDigest);

    // Digest without nonce
    responseDigest = [PHAPIRequest expectedSignatureValueForResponse:@"response body" nonce:nil secret:PUBLISHER_SECRET];
    expectedDigest = @"iNmo12xRqVAn_7quEvOSwhenEZA=";
    XCTAssertTrue([responseDigest isEqualToString:expectedDigest], @"Digest mismatch. Expected %@ got %@", expectedDigest, responseDigest);
}

- (void)testRequestParameters
{
    [PHAPIRequest setSession:@"test_session"];
    
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    
    NSNumber *theNetworkStatus = @(PHNetworkStatus());
    
    NSString *theRequestURL = [[self URLForRequest:request] absoluteString];
    NSDictionary *signedParameters = [request signedParameters];

    // Test for existence of parameters
    NSString
        *session   = [signedParameters valueForKey:@"session"],
        *token     = [signedParameters valueForKey:@"token"],
        *signature = [signedParameters valueForKey:@"sig4"],
        *nonce     = [signedParameters valueForKey:@"nonce"];

    XCTAssertEqualObjects(theNetworkStatus, signedParameters[@"connection"], @"Network status "
                "indicated by the request object doesn't match the expected one!");
    XCTAssertNotNil(session, @"Required session param is missing!");
    XCTAssertNotNil(token, @"Required token param is missing!");
    XCTAssertTrue(0 < [signature length], @"Required signature param is missing!");
    XCTAssertNotNil(nonce, @"Required nonce param is missing!");

    NSString *parameterString = [request signedParameterString];
    XCTAssertNotNil(parameterString, @"Parameter string is nil?");

    NSString *tokenParam = [NSString stringWithFormat:@"token=%@",token];
    XCTAssertFalse([parameterString rangeOfString:tokenParam].location == NSNotFound,
                  @"Token parameter not present!");

    NSString *signatureParam = [NSString stringWithFormat:@"sig4=%@",signature];
    XCTAssertFalse([parameterString rangeOfString:signatureParam].location == NSNotFound,
                  @"Signature parameter not present!");

    NSString *nonceParam = [NSString stringWithFormat:@"nonce=%@",nonce];
    XCTAssertFalse([parameterString rangeOfString:nonceParam].location == NSNotFound,
                  @"Nonce parameter not present!");

    NSString *theConnectionParam = [NSString stringWithFormat:@"connection=%@", theNetworkStatus];
    XCTAssertFalse([theRequestURL rangeOfString:theConnectionParam].length == 0,
                  @"Expected connection parameter is missed in the request URL!");
    
    // Test IDFV parameter

    NSString *theIDFV = signedParameters[@"idfv"];
    NSNumber *theAdTrackingFlag = signedParameters[@"tracking"];

    if (PH_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        NSString *theExpectedIDFV = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSNumber *theExpectedAdTrackingFlag = @([[ASIdentifierManager sharedManager]
                    isAdvertisingTrackingEnabled]);

        XCTAssertEqualObjects(theIDFV, theExpectedIDFV, @"Invalid IDFV value!");
        XCTAssertEqualObjects(theAdTrackingFlag, theExpectedAdTrackingFlag, @"Incorect Ad tracking "
                    "value");
        
        NSString *theIDFVParameter = [NSString stringWithFormat:@"idfv=%@", theIDFV];
        XCTAssertTrue([theRequestURL rangeOfString:theIDFVParameter].length > 0, @"IDFV is missed"
                    " from the request URL");
    }
    else
    {
        XCTAssertNil(theIDFV, @"IDFV is not available on iOS earlier than 6.0.");
        XCTAssertNil(theAdTrackingFlag, @"Ad tracking flag isn't available on iOS earlier than 6.0");

        XCTAssertTrue([theRequestURL rangeOfString:@"idfv="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
        XCTAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
        XCTAssertTrue([theRequestURL rangeOfString:@"tracking="].length == 0, @"This parameter "
                    "should be omitted on system < 6.0.");
    }
}

- (void)testMACParameterCase1
{
    // Set opt-out status to NO to get a full set of request parameters.
    [PHAPIRequest setOptOutStatus:NO];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    NSString *theMAC = [theSignedParameters objectForKey:@"mac"];

#if PH_USE_MAC_ADDRESS == 1
    // MAC should be sent on iOS 5 and earlier.
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {

        XCTAssertNotNil(theMAC, @"MAC param is missing!");
        XCTAssertFalse([theRequestURL rangeOfString:@"mac="].location == NSNotFound, @"MAC "
                    "param is missing: %@", theRequestURL);
    }
    else
    {
        NSString *theUnexpectedMACMessage = @"MAC should not be sent on iOS 6 and later";

        XCTAssertNil([theSignedParameters objectForKey:@"mac"], @"%@!", theUnexpectedMACMessage);
        XCTAssertTrue([theRequestURL rangeOfString:@"mac="].length == 0, @"%@: %@",
                    theUnexpectedMACMessage, theRequestURL);
    }
#else
    STAssertNil(theMAC, @"MAC param is present!");
    STAssertTrue([theRequestURL rangeOfString:@"mac="].location == NSNotFound, @"MAC param "
                "exists when it shouldn't: %@", theRequestURL);
#endif
}

- (void)testMACParameterCase2
{
    // Set opt-out status to YES to get request parameters without MAC.
    [PHAPIRequest setOptOutStatus:YES];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theUnexpectedMACMessage = @"MAC should not be sent for opted out users";

    XCTAssertNil([theSignedParameters objectForKey:@"mac"], @"%@!", theUnexpectedMACMessage);
    XCTAssertTrue([theRequestURL rangeOfString:@"mac="].length == 0, @"%@: %@",
                theUnexpectedMACMessage, theRequestURL);
}

- (void)testOptedInUser
{
    // User is opted-in.
    [PHAPIRequest setOptOutStatus:NO];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    XCTAssertEqualObjects(theSignedParameters[@"opt_out"], @(NO), @"Incorrect opt-out value!");
    XCTAssertTrue([theRequestURL rangeOfString:@"opt_out=0"].length > 0, @"Incorrect opt-out "
                "value!");
}

- (void)testOptedOutUser
{
    // User is opted-out.
    [PHAPIRequest setOptOutStatus:YES];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    XCTAssertEqualObjects(theSignedParameters[@"opt_out"], @(YES), @"Incorrect opt-out value!");
    XCTAssertTrue([theRequestURL rangeOfString:@"opt_out=1"].length > 0, @"Incorrect opt-out "
                "value!");

    // Revert out-out status.
    [PHAPIRequest setOptOutStatus:NO];
}

- (void)testCustomRequestParameters
{
    NSDictionary *signedParameters;
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    // Test what happens when they are not set
    NSString
        *customUDID       = [PHAPIRequest customUDID],
        *pluginIdentifier = [PHAPIRequest pluginIdentifier],
        *requestURLString = [[self URLForRequest:request] absoluteString];

    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    XCTAssertNil(customUDID, @"Custom UDID param is not nil!");
    XCTAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to nil
    [PHAPIRequest setCustomUDID:nil];
    [PHAPIRequest setPluginIdentifier:nil];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    XCTAssertNil(customUDID, @"Custom UDID param is not nil!");
    XCTAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to empty strings
    [PHAPIRequest setCustomUDID:@""];
    [PHAPIRequest setPluginIdentifier:@""];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    XCTAssertNil(customUDID, @"Custom UDID param is not nil!");
    XCTAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to [NSNull null]
    [PHAPIRequest setCustomUDID:(id)[NSNull null]];
    [PHAPIRequest setPluginIdentifier:(id)[NSNull null]];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    XCTAssertNil(customUDID, @"Custom UDID param is not nil!");
    XCTAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are longer than the allowed amount for plugin identifier (42)
    [PHAPIRequest setCustomUDID:@"12345678911234567892123456789312345678941234567895"];
    [PHAPIRequest setPluginIdentifier:@"12345678911234567892123456789312345678941234567895"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([customUDID isEqualToString:@"12345678911234567892123456789312345678941234567895"],
                 @"Custom UDID param is not 42 characters!"); // Stays the same...
    XCTAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not 42 characters!"); // Trimmed...
    XCTAssertTrue([pluginIdentifier length], @"Plugin identifier param is not 42 characters!");


    // Test what happens when they have mixed reserved characters
    [PHAPIRequest setCustomUDID:@"abcdefg:?#[]@/!$&'()*+,;=\"abcdefg"];
    [PHAPIRequest setPluginIdentifier:@"abcdefg:?#[]@/!$&'()*+,;=\"abcdefg"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([customUDID isEqualToString:@"abcdefgabcdefg"],
                 @"Custom UDID param is not stripped of reserved characters properly!"); // Stripped...
    XCTAssertTrue([pluginIdentifier isEqualToString:@"abcdefgabcdefg"],
                 @"Plugin identifier param is not stripped of reserved characters properly!"); // Stripped...

    // Test what happens when they have mixed reserved characters and at length 42 after
    [PHAPIRequest setCustomUDID:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"12"];
    [PHAPIRequest setPluginIdentifier:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"12"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([customUDID isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Custom UDID param is not stripped of reserved characters properly!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not stripped of reserved characters properly!");

    // Test what happens when they have mixed reserved characters and over length 42 after
    [PHAPIRequest setCustomUDID:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"1234567895"];
    [PHAPIRequest setPluginIdentifier:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"1234567895"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([customUDID isEqualToString:@"12345678911234567892123456789312345678941234567895"],
                 @"Custom UDID param is not stripped of reserved characters properly!"); // Stripped
    XCTAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not stripped of reserved characters properly!"); // Stripped and trimmed

    // Test what happens when it's only reserved characters
    [PHAPIRequest setCustomUDID:@":?#[]@/!$&'()*+,;=\""];
    [PHAPIRequest setPluginIdentifier:@":?#[]@/!$&'()*+,;=\""];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    XCTAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    XCTAssertNil(customUDID, @"Custom UDID param is not nil!");
    XCTAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    XCTAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test PHPublisherOpenRequest.customUDID property and PHAPIRequest property and class methods
    PHPublisherOpenRequest *openRequest = [PHPublisherOpenRequest requestForApp:PUBLISHER_TOKEN
                                                                         secret:PUBLISHER_SECRET];

    [openRequest setCustomUDID:@"one"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    XCTAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    XCTAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [request customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [openRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    [PHAPIRequest setCustomUDID:@"two"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    XCTAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    XCTAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [request customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [openRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    [request setCustomUDID:@"three"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    XCTAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    XCTAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [request customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [openRequest customUDID];
    XCTAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);
}

- (void)testURLProperty
{
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString     *desiredURLString = @"http://thisisatesturlstring.com";

    request.urlPath = desiredURLString;
    NSURL *theRequestURL = [self URLForRequest:request];
    XCTAssertFalse([[theRequestURL absoluteString] rangeOfString:desiredURLString].location == NSNotFound,
                  @"urlPath not present in signed URL!");

}

- (void)testSession
{
    XCTAssertNoThrow([PHAPIRequest setSession:@"test_session"], @"setting a session shouldn't throw an error");
    XCTAssertNoThrow([PHAPIRequest setSession:nil], @"clearing a session shouldn't throw");
}

- (void)testV4Signature
{
    // Case 1: Check signature generation with arbitrary identifiers.
    NSDictionary *theIdentifiers = @{ @"device": @"1111", @"ifa" : @"2222",
                @"mac" : @"beefbeefbeef", @"odin" : @"3333"};
    
    NSString *theSignature = [PHAPIRequest v4SignatureWithIdentifiers:theIdentifiers token:
                @"app-token" nonce:@"12345" signatureKey:@"app-secret"];
    XCTAssertEqualObjects(theSignature, @"ULwcjDFMPwhMCsZs-78HVjyAD-s", @"Incorect signature");
    
    // Case 2: Check signature generation with empty list of identifiers.
    theIdentifiers = @{};
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:theIdentifiers token:@"app-token" nonce:
                @"12345" signatureKey:@"app-secret"];
    XCTAssertEqualObjects(theSignature, @"yo9XmQWA5iISpqVwE-zNgkWZ7ZI", @"Incorect signature");

    // Case 3: Check signature generation with nil identifiers.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:@"12345"
                signatureKey:@"app-secret"];
    XCTAssertEqualObjects(theSignature, @"yo9XmQWA5iISpqVwE-zNgkWZ7ZI", @"Incorect signature");
    
    // Case 4: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:nil nonce:@"12345"
                signatureKey:@"app-secret"];
    XCTAssertNil(theSignature, @"Signature should be nil if application token is not specified.");

    // Case 5: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:nil
                signatureKey:@"app-secret"];
    XCTAssertNil(theSignature, @"Signature should be nil if nonce is not specified.");

    // Case 6: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:@"12345"
                signatureKey:nil];
    XCTAssertNil(theSignature, @"Signature should be nil if signature key is not specified.");
}

- (void)testOptOutStatus
{
    [PHAPIRequest setOptOutStatus:YES];
    XCTAssertTrue([PHAPIRequest optOutStatus], @"Incorrect opt-out status!");

    [PHAPIRequest setOptOutStatus:NO];
    XCTAssertFalse([PHAPIRequest optOutStatus], @"Incorrect opt-out status!");
}

- (void)testDefaultOptOutStatus
{
    // Clean up possible changes of the opt-out status to test default value.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PlayHavenOptOutStatus"];

    // This check relies on the presence of the PHDefaultUserIsOptedOut key in the app info
    // dictionary.
    XCTAssertTrue([PHAPIRequest optOutStatus], @"Incorrect default opt-out status!");
    
    [PHAPIRequest setOptOutStatus:NO];
    XCTAssertFalse([PHAPIRequest optOutStatus], @"Incorrect default opt-out status!");
}

- (void)testHTTPMethod
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    XCTAssertEqual(PHRequestHTTPGet, theRequest.HTTPMethod, @"Default HTTPMethod doesn't match the "
                "expected one!");
}

- (void)testNoRequestResponse
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    theRequest.delegate = self;
    [theRequest connectionDidFinishLoadingWithRequest:nil response:nil data:nil context:nil];
    
    XCTAssertTrue(self.requestFailed, @"Requests with nil response data should fail!");
    XCTAssertFalse(self.requestSucceeded, @"Requests with nil response data should fail!");
    XCTAssertEqual(self.reportedError.code, (NSInteger)PHAPIResponseErrorType, @"Reported error "
				"code doesn't match the expected one!");
    XCTAssertEqualObjects(self.reportedError.localizedDescription, @"Unexpected server response!",
                @"Reported error code doesn't match the expected one!");
}

- (void)testUnexpectedRequestResponse
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    NSArray *theUnexpectedResponse = @[@"value1", @"value2"];
    NSData *theResponseData = [NSJSONSerialization dataWithJSONObject:theUnexpectedResponse
                options:0 error:nil];
    XCTAssertNotNil(theResponseData, @"Cannot serialize test response!");
    
    theRequest.delegate = self;
    [theRequest connectionDidFinishLoadingWithRequest:nil response:nil data:theResponseData context:
                nil];
    
    XCTAssertTrue(self.requestFailed, @"Request with response that is not a dictionary should "
                "fail!");
    XCTAssertFalse(self.requestSucceeded, @"Request with response that is not a dictionary should "
                "fail!");
    XCTAssertEqual(self.reportedError.code, (NSInteger)PHAPIResponseErrorType, @"Reported error "
				"code doesn't match the expected one!");
    XCTAssertEqualObjects(self.reportedError.localizedDescription, @"Unexpected server response!",
                @"Reported error code doesn't match the expected one!");
}

- (void)testErrorRequestResponse
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    NSDictionary *theResponse = @{@"error" : @"Test error!", @"response" : @{}, @"errobj" : [NSNull
                null]};
    NSData *theResponseData = [NSJSONSerialization dataWithJSONObject:theResponse options:0 error:
                nil];
    XCTAssertNotNil(theResponseData, @"Cannot serialize test response!");
    
    theRequest.delegate = self;
    [theRequest connectionDidFinishLoadingWithRequest:nil response:nil data:theResponseData context:
                nil];
    
    XCTAssertTrue(self.requestFailed, @"Request with error should fail!");
    XCTAssertFalse(self.requestSucceeded, @"Request with error should fail!");
    XCTAssertEqual(self.reportedError.code, (NSInteger)PHAPIResponseErrorType, @"Reported error "
				"code doesn't match the expected one!");
    NSString *theExpectedError = [NSString stringWithFormat:@"Server responded with the error: "
                "error - %@; response - %@;", theResponse[@"error"], theResponse[@"response"]];
    XCTAssertEqualObjects(self.reportedError.localizedDescription, theExpectedError,
                @"Reported error code doesn't match the expected one!");
}

- (void)testRequestResponseDigest
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    NSDictionary *theResponse = @{@"error" : [NSNull null], @"response" : @{}, @"errobj" : [NSNull
                null]};
    NSData *theResponseData = [NSJSONSerialization dataWithJSONObject:theResponse options:0 error:
                nil];
    XCTAssertNotNil(theResponseData, @"Cannot serialize test response!");
    
    NSURL *theURL = [NSURL URLWithString:@"http://www.playhaven.com"];
    NSHTTPURLResponse *theTestResponse = [[NSHTTPURLResponse alloc] initWithURL:theURL statusCode:
                200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
    XCTAssertNotNil(theTestResponse, @"Cannot create test response!");
    
    theRequest.delegate = self;
    [theRequest connectionDidFinishLoadingWithRequest:nil response:theTestResponse data:
                theResponseData context:nil];
    
    XCTAssertTrue(self.requestFailed, @"Request without digest should fail!");
    XCTAssertFalse(self.requestSucceeded, @"Request without digest should fail!");
    XCTAssertEqual(self.reportedError.code, (NSInteger)PHRequestDigestErrorType, @"Reported error "
				"code doesn't match the expected one!");
    NSString *theExpectedError = @"Signed response did not have valid signature.";
    XCTAssertEqualObjects(self.reportedError.localizedDescription, theExpectedError, @"Reported "
                "error code doesn't match the expected one!");
}

- (void)testSuccessfulRequestResponse
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    XCTAssertNotNil(theRequest, @"");
    
    NSURL *theRequestURL = [self URLForRequest:theRequest];
    XCTAssertNotNil(theRequestURL, @"Cannot obtain request URL!");
    XCTAssertNotNil(theRequest.signedParameters, @"Cannot obtain request signed parameters!");
    
    NSDictionary *theResponse = @{@"error" : [NSNull null], @"response" : @{}, @"errobj" : [NSNull
                null]};
    NSData *theResponseData = [NSJSONSerialization dataWithJSONObject:theResponse options:0 error:
                nil];
    XCTAssertNotNil(theResponseData, @"Cannot serialize test response!");
    
    NSString *theNonce = [theRequest.signedParameters valueForKey:@"nonce"];
    NSString *theExpectedDigest = [PHAPIRequest expectedSignatureValueForResponse:[[NSString alloc]
                initWithData:theResponseData encoding:NSUTF8StringEncoding] nonce:
                theNonce secret:theRequest.secret];
    
    NSURL *theURL = [NSURL URLWithString:@"http://www.playhaven.com"];
    NSHTTPURLResponse *theTestResponse = [[NSHTTPURLResponse alloc] initWithURL:theURL statusCode:
                200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"X-PH-DIGEST" : theExpectedDigest}];
    XCTAssertNotNil(theTestResponse, @"Cannot create test response!");
    
    theRequest.delegate = self;
    [theRequest connectionDidFinishLoadingWithRequest:nil response:theTestResponse data:
                theResponseData context:nil];
    
    XCTAssertFalse(self.requestFailed, @"Request with a digest should not fail!");
    XCTAssertTrue(self.requestSucceeded, @"Request with a digest should not fail!");
}

#pragma mark - PHAPIRequestDelegate

- (void)request:(PHAPIRequest *)aRequest didSucceedWithResponse:(NSDictionary *)aResponseData
{
    self.requestSucceeded = YES;
}

- (void)request:(PHAPIRequest *)aRequest didFailWithError:(NSError *)anError
{
    self.requestFailed = YES;
    self.reportedError = anError;
}

@end

@implementation PHAPIRequestResponseTest

- (void)setUp
{
    _request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    _request.delegate = self;
    _didProcess = NO;
}

- (void)testResponse
{
    NSDictionary *testDictionary     = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"awesomesause", @"awesome", nil];
    NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            testDictionary,@"response",
                                                            [NSNull null],@"error",
                                                            [NSNull null],@"errobj", nil];
    [_request processRequestResponse:responseDictionary];
}

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData
{
    XCTAssertNotNil(responseData, @"Expected responseData, got nil!");
    XCTAssertTrue([[responseData allKeys] count] == 1, @"Unexpected number of keys in response data!");
    XCTAssertTrue([@"awesomesause" isEqualToString:[responseData valueForKey:@"awesome"]],
                 @"Expected 'awesomesause' got %@",
                 [responseData valueForKey:@"awesome"]);
    _didProcess = YES;
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    XCTFail(@"Request failed with error, but it wasn't supposed to!");
}

- (void)tearDown
{
    XCTAssertTrue(_didProcess, @"Did not actually process request!");
}
@end

@implementation PHAPIRequestErrorTest

- (void)setUp
{
    _request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    _request.delegate = self;
    _didProcess = NO;
}

- (void)testResponse
{
    NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            kPHErrorDescription, @"error", nil];
    NSData *theResponseData = [NSJSONSerialization dataWithJSONObject:responseDictionary options:0
                error:nil];
    XCTAssertNotNil(theResponseData, @"Cannot serialize stub response!");
    
    [_request connectionDidFinishLoadingWithRequest:nil response:nil data:theResponseData context:
                nil];
}

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData
{
    XCTFail(@"Request failed succeeded, but it wasn't supposed to!");
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    XCTAssertTrue(0 < [[error localizedDescription] rangeOfString:kPHErrorDescription].length,
                @"Expected error but got nil!");
    _didProcess = YES;
}

- (void)tearDown
{
    XCTAssertTrue(_didProcess, @"Did not actually process request!");
}
@end

@implementation PHAPIRequestByHashCodeTest

- (void)testRequestByHashCode
{
    int hashCode = 100;

    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    request.hashCode = hashCode;

    PHAPIRequest *retrievedRequest = [PHAPIRequest requestWithHashCode:hashCode];
    XCTAssertTrue(request == retrievedRequest, @"Request was not able to be retrieved by hashCode.");
    XCTAssertNil([PHAPIRequest requestWithHashCode:hashCode+1], @"Non-existent hashCode returned a request.");

    [request cancel];
    XCTAssertNil([PHAPIRequest requestWithHashCode:hashCode], @"Canceled request was retrieved by hashCode");
}

- (void)testRequestCancelByHashCode
{
    int hashCode = 200;

    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    request.hashCode = hashCode;

    XCTAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode] == 1, @"Request was not canceled!");
    XCTAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode] == 0, @"Canceled request was canceled again.");
    XCTAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode+1] == 0, @"Nonexistent request was canceled.");
    XCTAssertFalse([[PHAPIRequest allRequests] containsObject:request], @"Request was not removed from request array!");
}
@end
