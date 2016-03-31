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

 EventsViewController.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/27/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "EventsViewController.h"
#import "InfoViewController.h"

static NSString *const kPHEventsInfoMessage = @"EventsInfoMessage";

@interface EventsViewController ()
@property (nonatomic, retain) PHEventRequest *eventRequest;
@property (nonatomic, retain) UIPopoverController *infoPopoverController;
@property (nonatomic, assign) IBOutlet UIButton *infoButton;
@end

@implementation EventsViewController

- (void)startRequest
{
    NSString *theEventJSON = self.eventJSONTextField.text;
    theEventJSON = 0 < [theEventJSON length] ? theEventJSON : self.eventJSONTextField.placeholder;
    
    if (0 == [theEventJSON length])
    {
        [self addMessage:@"Cannot create event object with empty JSON!"];
        return;
    }

    NSData *jsonData = [theEventJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *theError = nil;
    NSDictionary *theDecodedEvent = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&theError] : nil;
    
    if (nil == theDecodedEvent)
    {
        [self addMessage:[NSString stringWithFormat:@"Cannot decode the specified JSON: %@",
                    theError]];
        return;
    }

    PHEvent *theEvent = [PHEvent eventWithProperties:theDecodedEvent];
    
    if (nil == theEvent)
    {
        [self addMessage:@"Cannot create event object with the specified JSON!"];
        return;
    }

    [super startRequest];
    
    self.eventRequest = [PHEventRequest requestForApp:self.token secret:self.secret event:theEvent];
    self.eventRequest.delegate = self;
    [self.eventRequest send];

    [self.eventJSONTextField resignFirstResponder];
}

- (IBAction)showInfo:(id)aSender
{
    InfoViewController *theInfoViewController = [InfoViewController new];
    [theInfoViewController view];
    theInfoViewController.infoTextView.text = NSLocalizedString(kPHEventsInfoMessage, @"");
    
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

#pragma mark - PHAPIRequestDelegate

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData
{
    NSString *message = [NSString stringWithFormat:@"[OK] Success with response: %@", responseData];
    [self addMessage:message];

    [self finishRequest];
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"[ERROR] Failed with error: %@", error];
    [self addMessage:message];

    [self finishRequest];
}

- (void)finishRequest
{
    self.eventRequest = nil;
    [super finishRequest];
}

@end
