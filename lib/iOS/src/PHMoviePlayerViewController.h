//
//  PHMoviePlayerViewController.h
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/23/15.
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PHBeaconManager.h"
#import "PHPreloadingObject.h"

@interface PHMoviePlayerViewController : MPMoviePlayerViewController

@property (nonatomic, strong) UIWebView *uiLayer;
@property (nonatomic, assign) BOOL isRewarded;

- (void)showUIOverlay:(NSURL *)overlayURL;
- (void)videoWillSkip;
- (void)videoWillReplay;
- (void)videoWillCancelLoad;
- (void)loadRemoteFile:(PHPreloadingObject *)preloadingObject;
- (void)tearDown;

@end