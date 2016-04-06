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

 InfoViewController.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/28/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "InfoViewController.h"

@interface InfoViewController ()
@property (nonatomic, assign) IBOutlet UIButton *dismissButton;
@end

@implementation InfoViewController

- (CGSize)contentSizeForViewInPopover
{
    return CGSizeMake(320, 400);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM())
    {
        self.infoTextView.frame = self.view.bounds;
        self.dismissButton.hidden = YES;
    }
}

- (IBAction)dismiss:(id)aSender
{
    if (UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM())
    {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

@end
