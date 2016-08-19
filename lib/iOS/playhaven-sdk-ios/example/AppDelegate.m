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

 exampleAppDelegate.m
 example

 Created by Jesus Fernandez on 4/25/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "AppDelegate.h"
#import "IAPHelper.h"
#import "PlayHavenSDK.h"
#import "PlayHavenAppIdentity.h"
#import "PHConstants.h"

#if RUN_KIF_TESTS
#import "PHTestController.h"
#endif

static NSString *const kPHApplicationTokenKey = @"applicationToken";
static NSString *const kPHApplicationSecretKey = @"applicationSecret";

@interface AppDelegate ()
@property (nonatomic, retain) NSDictionary *remoteNotificationInfo;
@end

@implementation AppDelegate
@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configurePlayHaven];

    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;

    [self.window makeKeyAndVisible];
    [[IAPHelper sharedIAPHelper] restorePurchases];

    [PHAPIRequest setOptOutStatus:NO];

#if RUN_KIF_TESTS
    [[PHTestController sharedInstance] startTestingWithCompletionBlock:^{
        // Exit after the tests complete so that CI knows we're done
        exit([[PHTestController sharedInstance] failureCount]);
    }];
#endif

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    PHSetBaseURL([[NSUserDefaults standardUserDefaults] stringForKey:@"PHBaseUrl"]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
            sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    PH_DEBUG(@"URL to open: %@", url);
    [[[UIAlertView alloc] initWithTitle:@"URL Opened"
                                 message:[NSString stringWithFormat:@"Application got URL: %@", [url absoluteString]]
                                delegate:nil
                       cancelButtonTitle:nil
                       otherButtonTitles:@"OK", nil] show];

    return YES;
}

- (void)dealloc
{
    [[PlayHavenAppIdentity sharedIdentity] removeObserver:self forKeyPath:kPHApplicationTokenKey];
    [[PlayHavenAppIdentity sharedIdentity] removeObserver:self forKeyPath:kPHApplicationSecretKey];
}

#pragma mark - Private

- (void)configurePlayHaven
{
    PlayHavenAppIdentity *theAppIdentity = [PlayHavenAppIdentity sharedIdentity];

    if (0 == [theAppIdentity.applicationToken length])
    {
        theAppIdentity.applicationToken = @"8ae979ddcdaf450996e897322169d26c";
    }

    if (0 == [theAppIdentity.applicationSecret length])
    {
        theAppIdentity.applicationSecret = @"080d853e433a4468ba3315953b22615e";
    }
}

@end
