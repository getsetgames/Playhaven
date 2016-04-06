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

 PublisherContentViewController.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 4/25/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PublisherContentViewController.h"
#import "IAPHelper.h"
#import "InfoViewController.h"
#import "PHContent.h"
#import "PHBeaconObject.h"
#import "PHBeaconManager.h"
#import "PHPreloadingObject.h"
#import "PHPreloader.h"
#import "PHReward.h"
#import "PHMoviePlayerViewController.h"

static NSString *const kPHCustomDimensionsInfoMessage = @"CustomDimensionsInfoMessage";

@interface PHPublisherContentRequest (Properties)
@property (nonatomic, strong, readonly) NSString *contentUnitID;
@property (nonatomic, strong, readonly) NSString *messageID;
@end

@interface PublisherContentViewController ()
@property (nonatomic, retain) NSMutableSet *sentRequests;
@property (nonatomic, assign) IBOutlet UITextField *customDimensionsField;
@property (nonatomic, assign) IBOutlet UIButton *infoButton;
@property (nonatomic, retain) UIPopoverController *infoPopoverController;
@end

@implementation PublisherContentViewController
@synthesize placementField = _placementField;
@synthesize request        = _request;
@synthesize showsOverlaySwitch;
@synthesize animateSwitch;

- (void)dealloc
{
    // Clean up all the remaining content requests initiated by the controller
    [PHAPIRequest cancelAllRequestsWithDelegate:self];
}

- (void)startRequest
{
    if (self.request == nil) {
        
        NSDictionary *theCustomDimensions = [self customDimensions];
        if (0 < [self.customDimensionsField.text length] && nil == theCustomDimensions)
        {
            // Do not send request if custom dimensions field contains invalid JSON
            return;
        }

        [super startRequest];

        //[self.placementField resignFirstResponder];

        NSString *placement = (0 < [self.placementField.text length]) ?
                                    self.placementField.text :
                                    @"more_games";

        PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:self.token
                                                                               secret:self.secret
                                                                            placement:placement
                                                                             delegate:self];
        [request setShowsOverlayImmediately:[showsOverlaySwitch isOn]];
        [request setAnimated:[animateSwitch isOn]];
        [request addDimensionsFromDictionary:theCustomDimensions];
        
        [request send];

        [self setRequest:request];

        [self.navigationItem.rightBarButtonItem setTitle:@"Cancel"];

    } else {
        [self addMessage:@"Request canceled!"];

        self.request.delegate = nil;
        [self.request cancel];
        self.request = nil;
        [self.navigationItem.rightBarButtonItem setTitle:@"Start"];
    }
}

- (void)finishRequest
{
    [super finishRequest];

    // Cleaning up after a completed request
    self.request = nil;
    [self.navigationItem.rightBarButtonItem setTitle:@"Start"];
}

#pragma mark -

- (void)sendRequest:(PHPublisherContentRequest *)aRequest
{
    if (nil == aRequest)
    {
        return;
    }

    if (nil == self.sentRequests)
    {
        self.sentRequests = [NSMutableSet set];
    }

    [self.sentRequests addObject:aRequest];

    aRequest.delegate = self;
    [aRequest send];
}

- (IBAction)showCustomDimensionsInfo:(id)aSender
{
    InfoViewController *theInfoViewController = [InfoViewController new];
    [theInfoViewController view];
    theInfoViewController.infoTextView.font = [UIFont systemFontOfSize:12];
    theInfoViewController.infoTextView.text = NSLocalizedString(kPHCustomDimensionsInfoMessage,
                @"");
    
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM())
    {
        if (nil == self.infoPopoverController)
        {
            self.infoPopoverController = [[UIPopoverController alloc]
                        initWithContentViewController:theInfoViewController];
        }

        [self.infoPopoverController presentPopoverFromRect:self.infoButton.frame inView:
                    self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [self presentViewController:theInfoViewController animated:YES completion:NULL];
    }
}

- (NSString *)descriptionForRequest:(PHPublisherContentRequest *)request
{
    if (request.placement)
        return [NSString stringWithFormat:@"placement - %@", request.placement];
    else if (request.contentUnitID && request.messageID)
        return [NSString stringWithFormat:@"content unit id - %@, message id - %@", request.contentUnitID, request.messageID];
    else
        return [NSString stringWithFormat:@"empty request"];
}

#pragma mark - PHPublisherContentRequestDelegate
- (void)requestWillGetContent:(PHPublisherContentRequest *)request
{
    NSString *message = [NSString stringWithFormat:@"Getting content for %@", [self descriptionForRequest:request]];
    [self addMessage:message];

    NSLog(@"Request (%@) will get content", [self descriptionForRequest:request]);
}

- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    NSString *message = [NSString stringWithFormat:@"Got content for %@", [self descriptionForRequest:request]];
    [self addMessage:message];

    NSLog(@"Request (%@) did get content", [self descriptionForRequest:request]);

    // Time is not tracked for requests created outside this view controller, like the ones passed
    // to - [PublisherContentViewController sendRequest:]
    if (request == self.request)
    {
        [self addElapsedTime];
    }
}

- (void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    NSString *message = [NSString stringWithFormat:@"Preparing to display content: %@", content];
    [self addMessage:message];
    
    if (self.forceVideo.isOn) {
        NSInteger testCreativeId = 182412;
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_overlay" withExtension:@"html"];

        content.videoOverlayURL = url;
        
        NSString *path = [PHPreloader getFullPathFromCreativeId:testCreativeId];
        content.creativeId = (path) ? testCreativeId : 0;
    }

    NSLog(@"Request (%@) will display content", [self descriptionForRequest:request]);

    if (request == self.request)
    {
        [self addElapsedTime];
    }
}

- (void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content
{
    // This is a good place to clear any notification views attached to this request.
    [_notificationView clear];

    NSString *message = [NSString stringWithFormat:@"Displayed content: %@", content];
    [self addMessage:message];

    NSLog(@"Request (%@) did display content", [self descriptionForRequest:request]);

    if (request == self.request)
    {
        [self addElapsedTime];
    }
}

- (void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type
{
    NSString *message = [NSString stringWithFormat:@"[OK] User dismissed request: %@ of type %@", request, type];
    [self addMessage:message];

    NSLog(@"Request (%@) did dismiss with type: %@", [self descriptionForRequest:request], type.description);

    if (request == self.request)
    {
        [self finishRequest];
    }
    else
    {
        request.delegate = nil;
        [self.sentRequests removeObject:request];
    }
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"[ERROR] Failed with error: %@", error];
    [self addMessage:message];

    NSLog(@"Request (%@) did fail with error: %@",
            [self descriptionForRequest:(PHPublisherContentRequest *)request], error.description);

    if (request == self.request)
    {
        [self finishRequest];
    }
    else
    {
        request.delegate = nil;
        [self.sentRequests removeObject:request];
    }
}

- (void)request:(PHPublisherContentRequest *)request unlockedReward:(PHReward *)reward {
    NSString *message = [NSString stringWithFormat:@"Unlocked reward: %ld %@",
                (long)reward.quantity, reward.rewardName];
    [self addMessage:message];

    NSLog(@"Request (%@) unlocked reward: %ld %@.",
            [self descriptionForRequest:request], (long)reward.quantity, reward.rewardName);
}

- (void)request:(PHPublisherContentRequest *)request makePurchase:(PHPurchase *)purchase
{
    NSString *message = [NSString stringWithFormat:@"Initiating purchase for: %ld %@",
                (long)purchase.quantity, purchase.productIdentifier];
    [self addMessage:message];

    NSLog(@"Request (%@) initiating purchase: %ld %@.", [self descriptionForRequest:request],
                (long)purchase.quantity, purchase.productIdentifier);

    [[IAPHelper sharedIAPHelper] startPurchase:purchase];
}

#pragma - Notifications
/*
 * Refresh your notification view from the server each time it appears.
 * This way you can be sure the type and value of the notification is most
 * likely to match up to the content unit that will appear.
 */

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self startTimers];
    [[PHPublisherContentRequest requestForApp:self.token secret:self.secret placement:@"more_games" delegate:self] preload];

    _notificationView = [[PHNotificationView alloc] initWithApp:self.token secret:self.secret placement:@"more_games"];
    _notificationView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

}

- (void)viewDidUnload
{
    [self setPlacementField:nil];
    [super viewDidUnload];
    [_notificationView removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view addSubview:_notificationView];
    [_notificationView setCenter:CGPointMake(self.view.frame.size.width - 22, 19)];
    [_notificationView refresh];

    [[PHStoreProductViewController sharedInstance] setDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_notificationView removeFromSuperview];

    [[PHStoreProductViewController sharedInstance] setDelegate:nil];
}

#pragma mark - PHStoreProductViewControllerDelegate

- (void)storeProductViewController:(PHStoreProductViewController *)aController
            willPresentProductWithID:(NSString *)aProductID
{
    [self addMessage:[NSString stringWithFormat:@"Will present in-app store for product id: %@",
                aProductID]];
}

- (void)storeProductViewController:(PHStoreProductViewController *)aController
            didDismissProductWithID:(NSString *)aProductID
{
    [self addMessage:[NSString stringWithFormat:@"Did dismiss in-app store for product id: %@",
                aProductID]];
}

- (NSDictionary *)customDimensions
{
    NSDictionary *theCustomDimensions = nil;
    
    if (0 < [self.customDimensionsField.text length])
    {
        NSError *theError = nil;
        id theJSONObject = [NSJSONSerialization JSONObjectWithData:
                    [self.customDimensionsField.text dataUsingEncoding:NSUTF8StringEncoding]
                    options:0 error:&theError];
        if (nil == theJSONObject)
        {
            [self addMessage:[NSString stringWithFormat:@"[ERROR] Cannot convert custom "
                        "dimensions into a Foundation object: %@", theError]];
        }
        else if ([theJSONObject isKindOfClass:[NSDictionary class]])
        {
            theCustomDimensions = theJSONObject;
        }
        else
        {
            [self addMessage:@"[ERROR] Given JSON doesn't match the required JSON schema!"];
        }
    }
    
    return theCustomDimensions;
}

@end
