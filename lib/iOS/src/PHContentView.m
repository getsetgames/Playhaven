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
 
 PHContentView.m (formerly PHAdUnitView.m)
 playhaven-sdk-ios
 
 Created by Jesus Fernandez on 4/1/11.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHContentView.h"
#import "PHContent.h"
#import "NSObject+QueryComponents.h"
#import "PHConstants.h"
#import "PHStoreProductViewController.h"
#import "PHConnectionManager.h"
#import "PHResourceCacher.h"
#import "PHPreloader.h"
#import "PHCacheCreativeRequest.h"

#define MAX_MARGIN 20

@interface PHContentView (Private)
+ (void)clearContentViews;
+ (NSMutableSet *)allContentViews;
- (void)sizeToFitOrientation;
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation;
- (void)orientationDidChange;
- (void)viewDidShow;
- (void)viewDidDismiss;
- (void)loadTemplate;
- (void)handleDismiss:(NSDictionary *)queryComponents;
- (void)handleLoadContext:(NSDictionary *)queryComponents callback:(NSString*)callback;
//- (void)handleVideoSkip:(NSDictionary *)queryComponents;
- (UIActivityIndicatorView *)activityView;
- (void)dismissWithError:(NSError *)error;
- (void)closeView:(BOOL)animated;
- (void)prepareForReuse;
- (void)resetRedirects;
- (void)bounceOut;
- (void)bounceIn;
//- (void)handleLaunch:(NSDictionary *)queryComponents;
//- (void)dismissView;
@end

static NSMutableSet *allContentViews = nil;

@implementation PHContentView
@synthesize content    = _content;
@synthesize delegate   = _delegate;
@synthesize targetView = _targetView;

#pragma mark - Static Methods

+ (void)initialize
{
    if (self == [PHContentView class]) {
        [[NSNotificationCenter defaultCenter] addObserver:[PHContentView class]
                                                 selector:@selector(clearContentViews)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
}

+ (NSMutableSet *)allContentViews
{
    @synchronized (allContentViews) {
        if (allContentViews == nil) {
            allContentViews = [[NSMutableSet alloc] init];
        }
    }
    return allContentViews;
}

+ (void)clearContentViews
{
    @synchronized (allContentViews) {
        allContentViews = nil;
    }
}

- (void)contentViewsCallback:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:PHCONTENTVIEW_CALLBACK_NOTIFICATION]) {
        NSDictionary *callBack = (NSDictionary *)[notification object];
        [self sendCallback:[callBack valueForKey:@"callback"]
              withResponse:[callBack valueForKey:@"response"]
                     error:[callBack valueForKey:@"error"]];
    }
}

+ (PHContentView *)dequeueContentViewInstance
{
#ifdef PH_USE_CONTENT_VIEW_RECYCLING
    PHContentView *instance = [[PHContentView allContentViews] anyObject];
    if (!!instance) {
        [[PHContentView allContentViews] removeObject:instance];
    }
    
    return instance;
#else
    return nil;
#endif
}

+ (void)enqueueContentViewInstance:(PHContentView *)contentView
{
#ifdef PH_USE_CONTENT_VIEW_RECYCLING
    [[self allContentViews] addObject:contentView];
#endif
}

#pragma mark -
- (id)initWithContent:(PHContent *)content
{
    if ((self = [super initWithFrame:[[UIScreen mainScreen] applicationFrame]])) {
        NSInvocation
        *dismissRedirect     = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleDismiss:)]],
        *launchRedirect      = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleLaunch:callback:)]],
        *loadContextRedirect = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleLoadContext:callback:)]],
        *skipVideo           = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleVideoSkip:)]],
        *replayVideo         = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleVideoReplay:)]],
        *cancelLoad          = [NSInvocation invocationWithMethodSignature:
                                [[PHContentView class] instanceMethodSignatureForSelector:@selector(handleCancelLoad:)]];
        
        dismissRedirect.target   = self;
        dismissRedirect.selector = @selector(handleDismiss:);
        
        launchRedirect.target   = self;
        launchRedirect.selector = @selector(handleLaunch:callback:);
        
        loadContextRedirect.target   = self;
        loadContextRedirect.selector = @selector(handleLoadContext:callback:);
        
        skipVideo.target   = self;
        skipVideo.selector = @selector(handleVideoSkip:);
        
        replayVideo.target   = self;
        replayVideo.selector = @selector(handleVideoReplay:);
        
        cancelLoad.target   = self;
        cancelLoad.selector = @selector(handleCancelLoad:);
        
        
        _redirects = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                      dismissRedirect,     @"ph://dismiss",
                      launchRedirect,      @"ph://launch",
                      loadContextRedirect, @"ph://loadContext",
                      skipVideo,           @"ph://skip",
                      replayVideo,         @"ph://replay",
                      cancelLoad,          @"ph://loading_close",
                      nil];
        
#ifndef PH_UNIT_TESTING
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.accessibilityLabel = @"content view";
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        if ([_webView respondsToSelector:@selector(setSuppressesIncrementalRendering:)])
            [_webView setSuppressesIncrementalRendering:YES];
        if ([_webView respondsToSelector:@selector(setKeyboardDisplayRequiresUserAction:)])
            [_webView setKeyboardDisplayRequiresUserAction:NO];
#endif
#endif
        _webView.mediaPlaybackRequiresUserAction = NO;
        _webView.allowsInlineMediaPlayback = YES;
        _activeWebView = _webView;
        
        [self addSubview:_webView];
#endif
        
        self.content = content;
        self.hasNoAd = NO;
    }
    
    return self;
}

- (void)resetRedirects
{
#ifdef PH_USE_CONTENT_VIEW_RECYCLING
    NSEnumerator *keyEnumerator = [[_redirects allKeys] objectEnumerator];
    NSString     *key;
    
    while ((key = [keyEnumerator nextObject])) {
        NSInvocation *invocation = [_redirects valueForKey:key];
        if (invocation.target != self) {
            [_redirects removeObjectForKey:key];
        }
    }
#endif
}

- (void)prepareForReuse
{
    self.content  = nil;
    self.delegate = nil;
    
    [self resetRedirects];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.open();document.close();"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [PHURLLoader invalidateAllLoadersWithDelegate:self];
}

- (UIActivityIndicatorView *)activityView
{
    if (_activityView == nil) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.hidesWhenStopped = YES;
        [_activityView startAnimating];
    }
    
    return _activityView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [PHURLLoader invalidateAllLoadersWithDelegate:self];
}

- (void)orientationDidChange
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation != _orientation) {
        if (CGRectIsNull([self.content frameForOrientation:orientation])) {
            [self dismissWithError:PHCreateError(PHOrientationErrorType)];
            return;
        }
        
        if (self.content.transition == PHContentTransitionDialog) {
            CGFloat barHeight   = ([[UIApplication sharedApplication] isStatusBarHidden]) ? 0 : 20;
            CGRect contentFrame = CGRectOffset([self.content frameForOrientation:orientation], 0, barHeight);
            _webView.frame = contentFrame;
        }
        
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [self sizeToFitOrientation];
        [UIView commitAnimations];
    }
}

- (void)sizeToFitOrientation
{
    // On systems prior to iOS 8 window did apply transform to it's root views in order to implement rotation. On iOS 8 and greater rotation is implemented without applying transform to view hierarchy, so we don't need to manually adjust it.
    BOOL adjustTransform = PH_SYSTEM_VERSION_LESS_THAN(@"8.0");
    if (adjustTransform) {
        self.transform = CGAffineTransformIdentity;
    }
    
    CGRect frame = [UIScreen mainScreen].bounds;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2),
                                 frame.origin.y + ceil(frame.size.height/2));
    
    if (PH_SYSTEM_VERSION_LESS_THAN(@"8.0"))
    {
        CGFloat scale_factor = 1.0f;
        
        CGFloat width = floor(scale_factor * frame.size.width);
        CGFloat height = floor(scale_factor * frame.size.height);
        
        _orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsLandscape(_orientation)) {
            self.frame = CGRectMake(0, 0, height, width);
        } else {
            self.frame = CGRectMake(0, 0, width, height);
        }
    }
    else
    {
        self.frame = frame;
    }
    
    self.center = center;
    
    if (adjustTransform) {
        self.transform = [self transformForOrientation:_orientation];
    }
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(-M_PI/2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

- (NSDictionary *)getVideoItem:(NSDictionary *)items {
    NSDictionary *videoItem = nil;
    for (NSDictionary *item in items) {
        if ([item objectForKey:@"video"]) {
            videoItem = [item objectForKey:@"video"];
        }
    }
    
    return videoItem;
}

- (void)showVideo {
    NSDictionary *adContent = [self.content.context objectForKey:@"content"];
    NSDictionary *videoItem = [self getVideoItem:[adContent objectForKey:@"items"]];
    [self showVideo:adContent videoItemDict:videoItem];
}

- (void)showVideo:(NSDictionary *)adContent videoItemDict:(NSDictionary *)videoItem {
    if (!_moviePlayerController) {
        [[PHPreloader sharedPreloader] resetQueue];
        PHBeaconObject *beaconObject;
        PHBeaconManager *beaconManager;
        if (!videoItem) {
            return;
        }
        
        NSDictionary *beacons = [adContent objectForKey:@"beacons"];
        if (beacons) {
            beaconObject = [[PHBeaconObject alloc] init];
            [beaconObject addBeacons:beacons];
            beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:beaconObject];
        }
        
        NSString *filePath = [PHPreloader getFullPathFromCreativeId:[[videoItem objectForKey:@"creative_id"] intValue]];
        NSURL *contentURL = (filePath) ? [NSURL fileURLWithPath:filePath] : nil;
        NSError *err;
        if ([contentURL checkResourceIsReachableAndReturnError:&err] == NO) {
            contentURL = nil;
        }
        
        _moviePlayerController = [[PHMoviePlayerViewController alloc] initWithContentURL:contentURL];

        if ([[videoItem objectForKey:@"video_variety"] isEqualToString:@"rewarded"]) {
            _moviePlayerController.isRewarded = YES;
        }
        
        // if the requested video is not saved locally, pass to movieplayer to download
        if (!contentURL) {
            NSURL *remoteURL = [NSURL URLWithString:[[[videoItem objectForKey:@"normal"] objectForKey:@"PH_PORTRAIT"] objectForKey:@"url"]];
            NSInteger *creativeId = [[videoItem objectForKey:@"creative_id"] intValue];
            PHPreloadingObject *preloaderObject = [[PHPreloadingObject alloc] initWithBeaconManager:beaconManager url:remoteURL creativeId:creativeId];
            [_moviePlayerController loadRemoteFile:preloaderObject];
        }
        
        if (self.content.videoOverlayURL) {
            [_moviePlayerController showUIOverlay:self.content.videoOverlayURL];
            _moviePlayerController.uiLayer.delegate = self;
        }
        
        [_moviePlayerController.view setFrame:self.bounds];
        
        [self addSubview:_moviePlayerController.view];
    }
}

- (void)show:(BOOL)animated
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentViewsCallback:)
                                                 name:PHCONTENTVIEW_CALLBACK_NOTIFICATION
                                               object:nil];
    
    // TRACK_ORIENTATION see STOP_TRACK_ORIENTATION
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    NSURL *url = self.content.URL;
    
    if ([[[self.content.context objectForKey:@"content"] objectForKey:@"type"] isEqualToString:@"video"]) {
        NSDictionary *adContent = [self.content.context objectForKey:@"content"];
        NSDictionary *videoItem = [self getVideoItem:[adContent objectForKey:@"items"]];
        [self showVideo:adContent videoItemDict:videoItem];
        // Don't continue loading interstitial if we're not suppose to show post view cta
        
        _showPostVideoCTA = [[videoItem objectForKey:@"post_view_cta"] boolValue];
        if (!_showPostVideoCTA) {
            self.transform = CGAffineTransformIdentity;
            self.alpha     = 1.0;
            [self.targetView addSubview: self];
            [self sizeToFitOrientation];
            
            if (animated) {
                [self bounceIn];
            } else {
                [self viewDidShow];
            }            
            return;
        }
    }
    
    // Reset transforms before doing anything
    _webView.transform = CGAffineTransformIdentity;
    _webView.alpha     = 1.0;
    
    self.transform = CGAffineTransformIdentity;
    self.alpha     = 1.0;
    
    // Actually start showing
    _willAnimate = animated;
    [self.targetView addSubview: self];
    [self sizeToFitOrientation];
    
    [_webView setDelegate:self];
    
    [self loadTemplate:url];
    
    if (CGRectIsNull([self.content frameForOrientation:_orientation])) {
        // This is an invalid frame and we should dismiss immediately!
        [self dismissWithError:PHCreateError(PHOrientationErrorType)];
        return;
    }
    
    CGFloat barHeight = ([[UIApplication sharedApplication] isStatusBarHidden]) ? 0 : 20;
    
    if (self.content.transition == PHContentTransitionModal) { // Not really used, but not yet killed; may be in disrepair
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        CGFloat width, height;
        if (UIInterfaceOrientationIsPortrait(_orientation)) {
            width  = self.frame.size.width;
            height = self.frame.size.height;
        } else {
            width  = self.frame.size.height;
            height = self.frame.size.width;
        }
        
        _webView.frame = CGRectMake(0, barHeight, width, height - barHeight);
        
        [self activityView].center = _webView.center;
        
        if (animated) {
            CGAffineTransform oldTransform = self.transform;
            self.transform = CGAffineTransformTranslate(oldTransform, 0, self.frame.size.height);
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDuration:0.25];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(viewDidShow)];
            self.transform = oldTransform;
            [UIView commitAnimations];
        } else {
            [self viewDidShow];
        }
    } else if (self.content.transition == PHContentTransitionDialog) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.opaque = NO;
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        CGRect contentFrame = CGRectOffset([self.content frameForOrientation:orientation], 0, barHeight);
        
        _webView.frame = contentFrame;
        
        //_webView.layer.borderWidth = 1.0f;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.opaque = NO;
        
        if ([self.delegate respondsToSelector:@selector(borderColorForContentView:)]) {
            _webView.layer.borderColor = [[self.delegate borderColorForContentView:self] CGColor];
        } else {
            _webView.layer.borderColor = [[UIColor blackColor] CGColor];
        }
        
        [self activityView].center = _webView.center;
        
        if (animated) {
            [self bounceIn];
        } else {
            [self viewDidShow];
        }
    }
    
    [self addSubview:[self activityView]];
    
}

- (void)dismiss:(BOOL)animated
{
    [self closeView:animated];
}

- (void)dismissFromButton
{
    NSDictionary *queryComponents = [NSDictionary dictionaryWithObjectsAndKeys:
                                     self.content.closeButtonURLPath, @"ping", nil];
    [self handleDismiss:queryComponents];
}

- (void)dismissWithError:(NSError *)error
{
    // This is here because get called 2x
    // first from handleLoadContext:
    // second from webView:didFailLoadWithError:
    // Only need to handle once
    if (self.delegate == nil)
        return;
    
    id oldDelegate = self.delegate;
    self.delegate = nil;
    [self closeView:_willAnimate];
    
    if ([oldDelegate respondsToSelector:(@selector(contentView:didFailWithError:))]) {
        PH_LOG(@"Error with content view: %@", [error localizedDescription]);
        [oldDelegate contentView:self didFailWithError:error];
    }
}

- (void)closeView:(BOOL)animated
{
    [_webView setDelegate:nil];
    [_webView stopLoading];
    
    _willAnimate = animated;
    if (self.content.transition == PHContentTransitionModal) {
        if (animated) {
            CGAffineTransform oldTransform = self.transform;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDuration:0.25];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(viewDidDismiss)];
            self.transform = CGAffineTransformTranslate(oldTransform, 0, self.frame.size.height);
            [UIView commitAnimations];
        } else {
            [self viewDidDismiss];
        }
    } else if (self.content.transition == PHContentTransitionDialog) {
        if (_willAnimate) {
            [self bounceOut];
        } else {
            [self viewDidDismiss];
        }
    }
    
    [self destroyPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PHCONTENTVIEW_CALLBACK_NOTIFICATION
                                                  object:nil];
    
    // STOP_TRACK_ORIENTATION see TRACK_ORIENTATION
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)templateLoaded:(NSNotification *)notification
{
    NSURLRequest  *request  = [notification.userInfo objectForKey:@"request"];
    
    if ([request.URL.absoluteString isEqualToString:self.content.URL.absoluteString]) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:PH_PREFETCH_CALLBACK_NOTIFICATION
                                                      object:nil];
        [self loadTemplate:self.content.URL];
        
    }
}

- (void)loadTemplate:(NSURL *)url
{
    [_webView stopLoading];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:PH_REQUEST_TIMEOUT];
    
    if ([PHResourceCacher isRequestPending:[[request URL] absoluteString]]) {
        PH_NOTE(@"Template is already being downloaded. Will come back when complete!");
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(templateLoaded:)
                                                     name:PH_PREFETCH_CALLBACK_NOTIFICATION
                                                   object:nil];
    } else {
        [PHResourceCacher pause];
        
        PH_LOG(@"Loading template from network or cache: %@", url);
        [_webView loadRequest:request];
    }
}

- (void)viewDidShow
{
    if ([self.delegate respondsToSelector:(@selector(contentViewDidShow:))]) {
        [self.delegate contentViewDidShow:self];
    }
}

- (void)viewDidDismiss
{
    id oldDelegate = self.delegate;
    [self prepareForReuse];
    
    if ([oldDelegate respondsToSelector:(@selector(contentViewDidDismiss:))]) {
        [oldDelegate contentViewDidDismiss:self];
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    _activeWebView = webView;
    NSURL *url = request.URL;
    NSString *urlPath;
    if ([url host] == nil) {
        // This can be nil if loading files from the local cache. The url host being nil caused the urlPath
        // not to be generated properly and the UIWebview load to fail.
        return YES;
    }
    else
        urlPath = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
    
    NSInvocation *redirect = [_redirects valueForKey:urlPath];
    [redirect retainArguments];
    
    if (redirect) {
        
        NSDictionary *queryComponents = [url queryComponents];
        NSString     *callback        = [queryComponents valueForKey:@"callback"];
        NSString     *contextString   = [queryComponents valueForKey:@"context"];
        
        // Logging for automation, this is a no-op when not automating
        // TODO: This is not the correct way of doing this.  Should fix later
        if ([self respondsToSelector:@selector(_logRedirectForAutomation:callback:)]) {
            [self performSelector:@selector(_logRedirectForAutomation:callback:) withObject:urlPath withObject:callback];
        }
        
        NSData *jsonData = [contextString dataUsingEncoding:NSUTF8StringEncoding];
        id parserObject = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil] : nil;
        NSDictionary *context = ([parserObject isKindOfClass:[NSDictionary class]]) ? (NSDictionary*) parserObject: nil;
        
        PH_LOG(@"Redirecting request with callback: %@ to dispatch %@", callback, urlPath);
        switch ([[redirect methodSignature] numberOfArguments]) {
            case 5:
            {
                __unsafe_unretained id unsafeSelf = self;
                [redirect setArgument:&unsafeSelf atIndex:4];
            }
            case 4:
                [redirect setArgument:&callback atIndex:3];
            case 3:
                [redirect setArgument:&context atIndex:2];
            default:
                break;
        }
        
        // NOTE: It's important to keep the invocation object around while we're invoking. This will prevent occasional EXC_BAD_ACCESS errors.
        [redirect invoke];
        
        return NO;
    }
    
    return ![[url scheme] isEqualToString:@"ph"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self dismissWithError:error];
    [PHResourceCacher resume];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // This is a fix that primarily affects iOS versions older than 4.1, it should prevent http requests
    // from leaking memory from the webview. Newer iOS versions are unaffected by the bug or the fix.
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    
    [[self activityView] stopAnimating];
    
    if ([self.delegate respondsToSelector:(@selector(contentViewDidLoad:))]) {
        [self.delegate contentViewDidLoad:self];
    }
    
    [PHResourceCacher resume];
}

- (void)continueOrDismiss {
    if (self.content.URL) {
        [self loadTemplate:self.content.URL];
        _moviePlayerController = nil;
    } else {
        [self dismiss:NO];
    }
}

#pragma mark -
#pragma mark Redirects
- (void)redirectRequest:(NSString *)urlPath toTarget:(id)target action:(SEL)action
{
    if (!!target) {
        NSInvocation *redirect = [NSInvocation invocationWithMethodSignature:[[target class] instanceMethodSignatureForSelector:action]];
        redirect.target   = target;
        redirect.selector = action;
        
        [_redirects setValue:redirect forKey:urlPath];
    } else {
        [_redirects setValue:nil forKey:urlPath];
    }
}

- (void)handleLaunch:(NSDictionary *)queryComponents callback:(NSString *)callback
{
    NSString *urlPath = [queryComponents valueForKey:@"url"];
    if (!!urlPath && [urlPath isKindOfClass:[NSString class]]) {
        PHURLLoader *loader = [[PHURLLoader alloc] init];
        
        loader.targetURL = [NSURL URLWithString:urlPath];
        loader.delegate  = self;
        loader.context   = [NSDictionary dictionaryWithObjectsAndKeys:
                            callback,        @"callback",
                            queryComponents, @"queryComponents", nil];
#if PH_USE_STOREKIT != 0
        BOOL shouldUseInternal = [[queryComponents valueForKey:@"in_app_store_enabled"] boolValue] && ([SKStoreProductViewController class] != nil);
        loader.opensFinalURLOnDevice = !shouldUseInternal;
#endif
        
        [loader open];
    }
}

- (void)handleDismiss:(NSDictionary *)queryComponents {   
    if (!_showPostVideoCTA) {
        NSString *pingPath = [queryComponents valueForKey:@"ping"];
        if (!!pingPath && [pingPath isKindOfClass:[NSString class]]) {
            PHURLLoader *loader = [[PHURLLoader alloc] init];
            
            loader.opensFinalURLOnDevice = NO;
            loader.targetURL             = [NSURL URLWithString:pingPath];
            
            [loader open];
        }
        
        if ([queryComponents valueForKey:@"no_ad"] &&
            [[queryComponents valueForKey:@"no_ad"] boolValue] == YES) {
            self.hasNoAd = YES;
        }
        
        [self dismiss:_willAnimate];
    } else {
        [self destroyPlayer];
    }
    
    _showPostVideoCTA = NO;
}

- (void)handleLoadContext:(NSDictionary *)queryComponents callback:(NSString*)callback
{
    NSString *loadCommand = [NSString stringWithFormat:@"window.PlayHavenDispatchProtocolVersion = %d", PH_DISPATCH_PROTOCOL_VERSION];
    [_webView stringByEvaluatingJavaScriptFromString:loadCommand];
    [_moviePlayerController.uiLayer stringByEvaluatingJavaScriptFromString:loadCommand];
    
    if (![self sendCallback:callback withResponse:self.content.context error:nil]) {
        [self dismissWithError:PHCreateError(PHLoadContextErrorType)];
    };
}

- (void)handleVideoSkip:(NSDictionary *)queryComponents {
    [_moviePlayerController videoWillSkip];
}

- (void)handleCancelLoad:(NSDictionary *)queryComponents {
    [self destroyPlayer];
}

- (void)destroyPlayer {
    if (_moviePlayerController) {
        [_moviePlayerController tearDown];
        [_moviePlayerController.view removeFromSuperview];
        _moviePlayerController = nil;
    }
}

- (void)handleVideoReplay:(NSDictionary *)queryComponents {
    [self showVideo];
}

#pragma mark - callbacks
- (BOOL)sendCallback:(NSString *)callback withResponse:(id)response error:(id)error
{
    NSString *_callback = @"null", *_response = @"null", *_error = @"null";
    if (!!callback) {
        PH_LOG(@"Sending callback with id: %@", callback);
        _callback = callback;
    }
    
    if (!!response) {
        _response = [[NSString alloc] initWithData:response ? [NSJSONSerialization dataWithJSONObject:response options:0 error:nil] : nil encoding:NSUTF8StringEncoding];
    }
    
    if (!!error) {
        _error = [[NSString alloc] initWithData:error ? [NSJSONSerialization dataWithJSONObject:error options:0 error:nil] : nil encoding:NSUTF8StringEncoding];
    }
    
    NSString *callbackCommand = [NSString stringWithFormat:@"var PlayHavenAPICallback = (window[\"PlayHavenAPICallback\"])? PlayHavenAPICallback : function(c,r,e){try{PlayHaven.nativeAPI.callback(c,r,e);return \"OK\";}catch(err){ return JSON.stringify(err);}}; PlayHavenAPICallback(\"%@\",%@,%@)", _callback, _response, _error];
    NSString *callbackResponse = [_activeWebView stringByEvaluatingJavaScriptFromString:callbackCommand];
    
    // Log callback for automation, this is no-op outside of automation
    if ([self respondsToSelector:@selector(_logCallbackForAutomation:)]) {
        [self performSelector:@selector(_logCallbackForAutomation:) withObject:callback];
    }
    
    if ([callbackResponse isEqualToString:@"OK"]) {
        return YES;
    } else {
        PH_LOG(@"content template callback failed. If this is a recurring issue, please include this console message along with the following information in your support request: %@", callbackResponse);
        return YES;
    }
}

#pragma mark -
#pragma mark PHURLLoaderDelegate
- (void)loaderFinished:(PHURLLoader *)loader
{
    NSDictionary *contextData  = (NSDictionary *)loader.context;
    NSString     *callback     = [contextData valueForKey:@"callback"];
    
    NSDictionary *responseDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [loader.targetURL absoluteString], @"url", nil];
    
#if PH_USE_STOREKIT != 0
    NSDictionary *queryComponents = [contextData valueForKey:@"queryComponents"];
    BOOL shouldUseInternal = [[queryComponents valueForKey:@"in_app_store_enabled"] boolValue] && ([SKStoreProductViewController class] != nil);
    if (shouldUseInternal) {
        [[PHStoreProductViewController sharedInstance] showProductId:[queryComponents valueForKey:@"application_id"]];
    }
#endif
    
    [self sendCallback:callback
          withResponse:responseDict
                 error:nil];
}

- (void)loaderFailed:(PHURLLoader *)loader
{
    NSDictionary *contextData  = (NSDictionary *)loader.context;
    NSDictionary *responseDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [loader.targetURL absoluteString], @"url", nil];
    NSDictionary *errorDict    = [NSDictionary dictionaryWithObject:@"1" forKey:@"error"];
    
    [self sendCallback:[contextData valueForKey:@"callback"]
          withResponse:responseDict
                 error:errorDict];
}

#pragma mark - PH_DIALOG animation methods
#define ALPHA_OUT 0.0f
#define ALPHA_IN  1.0f

#define BOUNCE_OUT CGAffineTransformMakeScale(0.8, 0.8)
#define BOUNCE_MID CGAffineTransformMakeScale(1.1, 1.1)
#define BOUNCE_IN  CGAffineTransformIdentity

#define DURATION_1 0.125
#define DURATION_2 0.125

- (void)bounceIn
{
    _webView.transform = BOUNCE_OUT;
    _webView.alpha     = ALPHA_OUT;
    
    [UIView beginAnimations:@"bounce" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:DURATION_1];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(continueBounceIn)];
    
    _webView.transform = BOUNCE_MID;
    _webView.alpha     = ALPHA_IN;
    
    [UIView commitAnimations];
}

- (void)continueBounceIn
{
    _webView.transform = BOUNCE_MID;
    _webView.alpha     = ALPHA_IN;
    
    [UIView beginAnimations:@"bounce2" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:DURATION_2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(finishBounceIn)];
    
    _webView.transform = BOUNCE_IN;
    
    [UIView commitAnimations];
}

- (void)finishBounceIn
{
    _webView.transform = BOUNCE_IN;
    _webView.alpha     = ALPHA_IN;
    
    [self viewDidShow];
}

- (void)bounceOut
{
    _webView.transform = BOUNCE_IN;
    _webView.alpha     = ALPHA_IN;
    
    [UIView beginAnimations:@"bounce" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:DURATION_1];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(continueBounceOut)];
    
    _webView.transform = BOUNCE_MID;
    
    [UIView commitAnimations];
}

- (void)continueBounceOut
{
    _webView.transform = BOUNCE_MID;
    _webView.alpha     = ALPHA_IN;
    
    [UIView beginAnimations:@"bounce2" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:DURATION_2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(finishBounceOut)];
    
    _webView.transform = BOUNCE_OUT;
    _webView.alpha     = ALPHA_OUT;
    
    [UIView commitAnimations];
}

- (void)finishBounceOut
{
    _webView.transform = BOUNCE_OUT;
    _webView.alpha     = ALPHA_OUT;
    
    [self viewDidDismiss];
}
@end