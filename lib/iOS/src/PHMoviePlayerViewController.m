//
//  PHMoviePlayerViewController.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/23/15.
//
//

#import "PHMoviePlayerViewController.h"
#import "PHConstants.h"
#import "PHPreloader.h"

@interface PHMoviePlayerViewController() {
    NSTimer *_timer;
    NSTimer *_timeout;
}

@end

@implementation PHMoviePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer setShouldAutoplay:YES];
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [self.moviePlayer setRepeatMode:MPMovieRepeatModeNone];
    
    [self registerForEvents];
    [self startTimer];
}

- (void)videoWillSkip {
    [self.moviePlayer stop];
}

- (void)videoWillCancelLoad {
    [self.moviePlayer stop];
}

- (void)videoWillReplay {
    self.moviePlayer.currentPlaybackTime = 0;
}

- (void)registerForEvents {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleVideoComplete:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];

}

- (void)showUIOverlay:(NSURL *)overlayURL {
    self.uiLayer = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.uiLayer.backgroundColor = [UIColor clearColor];
    self.uiLayer.opaque = NO;
    self.uiLayer.tag = 5;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:overlayURL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:PH_REQUEST_TIMEOUT];
    
    [self.uiLayer loadRequest:request];
    [self.view addSubview:self.uiLayer];
}

- (void)startTimer {
    if (_timer) {
        [self stopTimer];
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                              target:self
                                            selector:@selector(updatePlaybackProgressFromTimer:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)updateUIWithProgress:(NSTimeInterval)playbackTime duration:(NSTimeInterval)duration {
    NSString *playbackProgressCommand = [NSString stringWithFormat:@"updatePlaybackProgress(%f, %f)", playbackTime, duration];
    [self.uiLayer stringByEvaluatingJavaScriptFromString:playbackProgressCommand];
}

- (void)loadRemoteFile:(PHPreloadingObject *)preloadingObject {
    [[PHPreloader sharedPreloader] resetQueue];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveData:)
                                                 name:PHDidReceiveDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishDownloading:)
                                                 name:PHDidFinishPreloadingNotification
                                               object:nil];
    
    PHPreloader *preloader = [PHPreloader sharedPreloader];
    [preloader startPreloading:preloadingObject];
}

- (void)tearDown {
    [self.uiLayer removeFromSuperview];
    self.uiLayer = nil;
}

#pragma mark -
#pragma mark PHPreloadingObject notifications

- (void)didReceiveData:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;

    NSString *downloadProgressCommand = [NSString stringWithFormat:@"updateDownloadProgress(%f)", preloadingObject.percentLoaded];
    [self.uiLayer stringByEvaluatingJavaScriptFromString:downloadProgressCommand];
}

- (void)didFinishDownloading:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PHDidReceiveDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PHDidFinishPreloadingNotification object:nil];
  
    PHPreloadingObject *preloadingObject = notification.object;
    
    self.moviePlayer.contentURL = [NSURL fileURLWithPath:[PHPreloader getFullPathFromCreativeId:preloadingObject.cacheObject.creativeId]];
    [self.moviePlayer play];

}

#pragma mark -
#pragma mark Application events

- (void)willEnterBackground {
    NSString *enterBackgroundCommand = [NSString stringWithFormat:@"willEnterBackground()"];
    [self.uiLayer stringByEvaluatingJavaScriptFromString:enterBackgroundCommand];
    [self stopTimer];
}

#pragma mark -
#pragma mark MPMoviePlayer notifications

- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer {
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) && (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)) {
        [self updateUIWithProgress:self.moviePlayer.currentPlaybackTime duration:self.moviePlayer.duration];
    }
}

- (void)handleVideoComplete:(NSNotification *)notification {
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    NSString *playbackProgressCommand = @"updatePlaybackProgress(1, 1)";
    [self.uiLayer stringByEvaluatingJavaScriptFromString:playbackProgressCommand];
    
    _timeout = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                target:self
                                              selector:@selector(sendTimoutNotification:)
                                              userInfo:nil
                                               repeats:NO];
    
}

- (void)sendTimoutNotification:(NSNotification *)notification {
    [_timeout invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:PH_VIDEO_TIMOUT_NOTIFICATION object:self];
}

@end
