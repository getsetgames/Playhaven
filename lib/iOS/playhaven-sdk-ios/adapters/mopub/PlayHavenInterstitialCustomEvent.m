/***
 *
 *  The MIT License(MIT)
 *
 *  Copyright (c) 2013 Lima Sky
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies of the substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 ***/

#import "PlayHavenInterstitialCustomEvent.h"
#import "MPInstanceProvider.h"
#import "MPLogging.h"

@interface MPInstanceProvider (PlayHavenInterstitials)

- (PHPublisherContentRequest *)buildPHFullscreenAdWithDelegate:(id<PHPublisherContentRequestDelegate>)delegate andToken:(NSString *)token andSecret:(NSString *)secret andPlacement:(NSString *)placement;

@end

@implementation MPInstanceProvider (PlayHavenInterstitials)

- (PHPublisherContentRequest *)buildPHFullscreenAdWithDelegate:(id<PHPublisherContentRequestDelegate>)delegate andToken:(NSString *)token andSecret:(NSString *)secret andPlacement:(NSString *)placement
{
	return [PHPublisherContentRequest requestForApp:token secret:secret placement:placement delegate:delegate];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface PlayHavenInterstitialCustomEvent ()

@property (nonatomic, retain) PHPublisherContentRequest *playhavenRequest;

@end

@implementation PlayHavenInterstitialCustomEvent

@synthesize playhavenRequest = _playhavenRequest;

#pragma mark - MPInterstitialCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    MPLogInfo(@"Requesting PlayHaven interstitial.");
    NSString *token = [info objectForKey:@"token"];
    NSString *secret = [info objectForKey:@"secret"];
    NSString *placement = [info objectForKey:@"placement"];
    
    if (token && secret && placement) {
        
        // If the PlayHavenRequester singleton has not been created yet, go ahead and
        // create it and have it cache off our PlayHaven token and secret.
        if(![PlayHavenRequester sharedRequester]) {
            [PlayHavenRequester createSharedRequesterWithToken:token andSecret:secret];
        }

        self.playhavenRequest = [[MPInstanceProvider sharedProvider] buildPHFullscreenAdWithDelegate:self andToken:token andSecret:secret andPlacement:placement];
        self.playhavenRequest.showsOverlayImmediately = NO;
        [self.playhavenRequest setAnimated:YES];
        [self.playhavenRequest preload];
    }
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    MPLogInfo(@"Showing PlayHaven interstitial.");
    [self.playhavenRequest send];
}

- (void)dealloc
{
    MPLogInfo(@"PlayHaven dealloc.");
    self.playhavenRequest.delegate = nil;
    self.playhavenRequest = nil;

    [super dealloc];
}

#pragma mark - PHPublisherContentRequestDelegate

- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    MPLogInfo(@"Successfully loaded PlayHaven interstitial.");

    [self.delegate interstitialCustomEvent:self didLoadAd:request];
}

- (void)request:(PHPublisherContentRequest *)request didFailWithError:(NSError *)error
{
    MPLogInfo(@"Failed to load PlayHaven interstitial.");

    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    MPLogInfo(@"PlayHaven PlayHaven will be shown.");

    [self.delegate interstitialCustomEventWillAppear:self];
}

- (void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content
{
    MPLogInfo(@"PlayHaven PlayHaven was shown.");

    [self.delegate interstitialCustomEventDidAppear:self];
}

- (void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type
{
    MPLogInfo(@"PlayHaven interstitial was dismissed.");

    if(type==PHPublisherNoContentTriggeredDismiss)
    {
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
    else
    {
        [self.delegate interstitialCustomEventWillDisappear:self];
        [self.delegate interstitialCustomEventDidDisappear:self];
    }
}

@end


@interface PlayHavenRequester ()

@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSString* secret;

@end

@implementation PlayHavenRequester

@synthesize token = _token;
@synthesize secret = _secret;

static PlayHavenRequester *sharedRequester = nil;

+ (PlayHavenRequester *)createSharedRequesterWithToken: (NSString*)token andSecret:(NSString*) secret
{
    if(!sharedRequester && token && secret) {
        sharedRequester = [[PlayHavenRequester alloc] initWithToken:token andSecret:secret];
    }
    return sharedRequester;
}

+ (PlayHavenRequester *)sharedRequester
{
    return sharedRequester;
}

- (id)initWithToken: (NSString*)token andSecret:(NSString*) secret
{
    self = [super init];
    if (self)
    {
        self.token = token;
        self.secret = secret;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        // Go ahead and call it on init to account for the app already being active.
        [self appDidBecomeActive];
    }
    return self;
}

- (void)appDidBecomeActive
{
    if (self.token && self.secret) {
        [[PHPublisherOpenRequest requestForApp:self.token secret:self.secret] send];
    }
}

- (void)dealloc
{
    [_token release];
    [_secret release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end

