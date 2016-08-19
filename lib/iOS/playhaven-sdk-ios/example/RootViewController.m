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

 RootViewController.m
 example

 Created by Jesus Fernandez on 4/25/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "RootViewController.h"
#import "PublisherOpenViewController.h"
#import "PublisherContentViewController.h"
#import "PublisherIAPTrackingViewController.h"
#import "PublisherCancelContentViewController.h"
#import "URLLoaderViewController.h"
#import "IAPViewController.h"
#import "IDViewController.h"
#import "PlayHavenAppIdentity.h"
#import "EventsViewController.h"

static NSString *kPHClassNameKey = @"ClassName";
static NSString *kPHControllerNameKey = @"ControllerName";
static NSString *kPHControllerDescriptionKey = @"ControllerDescription";
static NSString *kPHAccessibilityLabelKey = @"AccessibilityLabel";
static NSString *kPHDefaultsKeyBaseURL = @"PHBaseUrl";

@interface RootViewController ()
- (BOOL)isTokenAndSecretFilledIn;
- (void)loadTokenAndSecretFromDefaults;
- (void)saveTokenAndSecretToDefaults;
@property (nonatomic, retain) UIButton *clearCacheButton;
@property (nonatomic, readonly) NSArray *controllersInformation;
@property (nonatomic, retain) PHPublisherContentRequest *delayedRequest;
@end

@implementation RootViewController
@synthesize tokenField;
@synthesize secretField;
@synthesize optOutStatusSlider;
@synthesize serviceURLField;
@synthesize clearCacheButton;
@synthesize controllersInformation = _controllersInformation;

+ (void)initialize
{
    NSString *theBaseURL = [[NSUserDefaults standardUserDefaults] stringForKey:
                kPHDefaultsKeyBaseURL];

    if (0 < [theBaseURL length])
    {
        // Example app should be able to test against different end-points, like staging,
        // production, etc.. Developers integrating PlayHaven SDK must not change the base URL.
        PHSetBaseURL(theBaseURL);
    }
}

#pragma mark -
#pragma mark Private
- (BOOL)isTokenAndSecretFilledIn
{
    BOOL notNil   =  (self.tokenField.text && self.secretField.text);
    BOOL notEmpty = !([self.tokenField.text isEqualToString:@""] || [self.secretField.text isEqualToString:@""]);

    return notNil && notEmpty;
}

- (void)loadTokenAndSecretFromDefaults
{
    self.tokenField.text  = [PlayHavenAppIdentity sharedIdentity].applicationToken;
    self.secretField.text = [PlayHavenAppIdentity sharedIdentity].applicationSecret;
    self.serviceURLField.text = PHGetBaseURL();

    self.optOutStatusSlider.on = [PHAPIRequest optOutStatus];
    self.locationOptOutStatusSlider.on = [PHAPIRequest locationOptOutStatus];
}

- (void)saveTokenAndSecretToDefaults
{
    [PlayHavenAppIdentity sharedIdentity].applicationToken = self.tokenField.text;
    [PlayHavenAppIdentity sharedIdentity].applicationSecret = self.secretField.text;
}

#pragma mark -
#pragma mark UIViewController
- (UIView *)viewForTableFooter
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    clearCacheButton   = [UIButton buttonWithType:UIButtonTypeRoundedRect];

    clearCacheButton.frame = CGRectMake(20, 10, self.view.frame.size.width - 40, 30);

    [clearCacheButton setTitle:@"Cache Is Empty (0 Mb)" forState:UIControlStateDisabled];

    clearCacheButton.autoresizingMask = UIViewAutoresizingNone | UIViewAutoresizingFlexibleWidth;

    footerView.backgroundColor  = [UIColor colorWithRed:0.72157 green:0.75686 blue:0.78431 alpha:1.0];
    footerView.autoresizingMask = UIViewAutoresizingNone | UIViewAutoresizingFlexibleWidth;

    [footerView addSubview:clearCacheButton];

    return footerView;
}

- (void)updateCacheButton
{
    NSUInteger currentCacheUsage =
                       [[NSURLCache sharedURLCache] currentDiskUsage] +
                       [[NSURLCache sharedURLCache] currentMemoryUsage];

    if (currentCacheUsage) {
        CGFloat f_size = [[NSNumber numberWithUnsignedInteger:currentCacheUsage] floatValue] / 1024;

        NSString *s_size;

        if (f_size < 1024) s_size = [NSString stringWithFormat:@"(%.2f Kb)", f_size];
        else               s_size = [NSString stringWithFormat:@"(%.2f Mb)", f_size / 1024];

        [clearCacheButton setTitle:[NSString stringWithFormat:@"Clear Cache %@", s_size]
                          forState:UIControlStateNormal];
        [clearCacheButton setEnabled:YES];
    } else {
        [clearCacheButton setEnabled:NO];
    }

    [clearCacheButton addTarget:self action:@selector(clearCache:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clearCache:(id)sender
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self updateCacheButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"PlayHaven";

    NSDictionary *theAppInfo = [[NSBundle mainBundle] infoDictionary];
    self.applicationVersion.text = [NSString stringWithFormat:@"App Version %@; SDK %@",
                theAppInfo[(NSString *)kCFBundleVersionKey], PH_SDK_VERSION];

    UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(touchedToggleStatusBar:)];
    self.navigationItem.rightBarButtonItem = toggleButton;

    ((UITableView *)self.view).tableFooterView = [self viewForTableFooter];

    // Token and secret should be loaded prior to assigning a delegate to push provider to prevent
    // "Missing Credentials" alert being shown on attempt to open a push notifications with a
    // content unit.
    [self loadTokenAndSecretFromDefaults];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadTokenAndSecretFromDefaults];

    [self updateCacheButton];
}

- (void)applicationEnteredForeground:(NSNotification *)notification {
    serviceURLField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"PHBaseUrl"];
    tokenField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExampleToken"];
    secretField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExampleSecret"];
}

- (void)touchedToggleStatusBar:(id)sender
{
    BOOL statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
        [[UIApplication sharedApplication] setStatusBarHidden:!statusBarHidden withAnimation:UIStatusBarAnimationSlide];
    }

    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
}

- (IBAction)touchedOptOutStatusSlider:(id)sender
{
    [PHAPIRequest setOptOutStatus:self.optOutStatusSlider.on];
}

- (IBAction)touchedLocationOptOutStatusSlider:(id)sender {
    [PHAdRequest setLocationOptOutStatus:self.locationOptOutStatusSlider.on];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.controllersInformation count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.textLabel.text = [[self.controllersInformation objectAtIndex:indexPath.row]
                objectForKey:kPHControllerNameKey];
    cell.detailTextLabel.text = [[self.controllersInformation objectAtIndex:indexPath.row]
                objectForKey:kPHControllerDescriptionKey];
    cell.accessibilityLabel = [[self.controllersInformation objectAtIndex:indexPath.row]
                objectForKey:kPHAccessibilityLabelKey];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self navigateToControllerAtIndexPath:indexPath];
}

- (void)navigateToControllerAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isTokenAndSecretFilledIn]) {
        [self saveTokenAndSecretToDefaults];

        Class theControllerClass = NSClassFromString([[self.controllersInformation objectAtIndex:
                    indexPath.row] objectForKey:kPHClassNameKey]);
        UIViewController *theController = [theControllerClass new];
        theController.title = [[self.controllersInformation objectAtIndex:indexPath.row]
                    objectForKey:kPHControllerNameKey];

        if ([theController isKindOfClass:[ExampleViewController class]])
        {
            ExampleViewController *theExampleController = (ExampleViewController *)theController;
            theExampleController.token  = self.tokenField.text;
            theExampleController.secret = self.secretField.text;
        }
        [self.navigationController pushViewController:theController animated:YES];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Missing Credentials"
                                                        message:@"You must supply a PlayHaven API token and secret to use this app. To get a token and secret, please visit http://playhaven.com on your computer and sign up."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewDidUnload
{
    [self setTokenField:nil];
    [self setSecretField:nil];
    [self setOptOutStatusSlider:nil];
    [self setServiceURLField:nil];
    [super viewDidUnload];
}

#pragma mark - Controllers Information

- (NSArray *)controllersInformation
{
    if (nil == _controllersInformation)
    {
        _controllersInformation = @[@{kPHClassNameKey : NSStringFromClass(
                    [PublisherOpenViewController class]), kPHControllerNameKey : @"Open",
                    kPHControllerDescriptionKey : @"/publisher/open/",
                    kPHAccessibilityLabelKey : @"open"},

                    [self contentCellDescription],

                    @{kPHClassNameKey : NSStringFromClass([PublisherIAPTrackingViewController class]),
                    kPHControllerNameKey : @"IAP Tracking",
                    kPHControllerDescriptionKey : @""},

                    @{kPHClassNameKey : NSStringFromClass([EventsViewController class]),
                    kPHControllerNameKey : @"Custom Events",
                    kPHControllerDescriptionKey : @"/publisher/event/",
                    kPHAccessibilityLabelKey : @"events"},

                    @{kPHClassNameKey : NSStringFromClass([PublisherCancelContentViewController class]),
                    kPHControllerNameKey : @"Cancelled Content",
                    kPHControllerDescriptionKey :  @"This content will be cancelled at an awkward time.",
                    kPHAccessibilityLabelKey : @""},

                    @{kPHClassNameKey : NSStringFromClass([URLLoaderViewController class]),
                    kPHControllerNameKey : @"URL Loader",
                    kPHControllerDescriptionKey : @"Test loading device URLs",
                    kPHAccessibilityLabelKey : @"url loader"},

                    @{kPHClassNameKey : NSStringFromClass(
                    [IAPViewController class]), kPHControllerNameKey : @"IAP",
                    kPHControllerDescriptionKey : @"Test In-App Purchases",
                    kPHAccessibilityLabelKey : @"iap"},

                    @{kPHClassNameKey : NSStringFromClass([IDViewController class]),
                    kPHControllerNameKey : @"Identifiers",
                    kPHControllerDescriptionKey : @"All of them",
                    kPHAccessibilityLabelKey : @"identifiers"}];
    }
    return _controllersInformation;
}

- (NSDictionary *)contentCellDescription
{
    return @{kPHClassNameKey : NSStringFromClass([PublisherContentViewController class]),
                kPHControllerNameKey : @"Content",
                kPHControllerDescriptionKey : @"/publisher/content/",
                kPHAccessibilityLabelKey : @"content"};
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)aNavigationController
            didShowViewController:(UIViewController *)aViewController animated:(BOOL)anAnimated
{
    if ([aViewController isMemberOfClass:[PublisherContentViewController class]])
    {
        [(PublisherContentViewController *)aViewController sendRequest:self.delayedRequest];

        self.delayedRequest = nil;
        self.navigationController.delegate = nil;
    }
}
@end
