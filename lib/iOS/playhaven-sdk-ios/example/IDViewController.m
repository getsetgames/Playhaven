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

 IDViewController.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 12/17/12.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "IDViewController.h"
#import <AdSupport/AdSupport.h>
#import "PlayHavenSDK.h"
#import "PHNetworkUtil.h"

@interface IDViewController ()
@property (assign, nonatomic) IBOutlet UIView *containerView;
@end

@implementation IDViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
    {
        self.IDFVLabel.text = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    else
    {
        self.IDFVLabel.text = @"";
    }

    self.IFALabel.text  = [[[NSClassFromString(@"ASIdentifierManager") sharedManager] advertisingIdentifier] UUIDString];

    CFDataRef macBytes   = [[PHNetworkUtil sharedInstance] newMACBytes];

    if (NULL != macBytes)
    {
        self.MACLabel.text   = [[PHNetworkUtil sharedInstance] stringForMACBytes:macBytes];

        CFRelease(macBytes);
    }

    self.PHIDLabel.text = [PHAPIRequest session];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self adjustContainerViewFrame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setIFALabel:nil];
    [self setMACLabel:nil];
    [self setPHIDLabel:nil];
    [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
            duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self adjustContainerViewFrame];
}

#pragma mark - Private

- (void)adjustContainerViewFrame
{
    if (NSFoundationVersionNumber_iOS_6_1 < floor(NSFoundationVersionNumber))
    {
        const CGFloat kHLContainerViewOffset = 20.f;
        
        CGRect theUpdatedFrame = CGRectInset(self.view.bounds, kHLContainerViewOffset,
                    kHLContainerViewOffset);
        CGSize theStatusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
        CGFloat theContainerOffset = self.navigationController.navigationBar.frame.size.height +
                    MIN(theStatusBarSize.width, theStatusBarSize.height);

        theUpdatedFrame.origin.y += theContainerOffset;
        theUpdatedFrame.size.height -= theContainerOffset;
        self.containerView.frame = theUpdatedFrame;
    }
}

@end
