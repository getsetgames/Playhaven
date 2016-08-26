//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2015 Get Set Games Inc. All rights reserved.
//

#include "PlayhavenPrivatePCH.h"

#if PLATFORM_ANDROID

#include "Android/AndroidJNI.h"
#include "AndroidApplication.h"


#elif PLATFORM_IOS
#import "PlayHavenSDK.h"
#endif


#if PLATFORM_IOS

@interface PlayhavenFunctionsDelegate : NSObject<PHPublisherContentRequestDelegate>
{
}

@end

static PlayhavenFunctionsDelegate *phs;

@implementation PlayhavenFunctionsDelegate

+(void)load
{
    if (!phs)
    {
        phs = [[PlayhavenFunctionsDelegate alloc] init];
    }
}

-(id)init
{
    self = [super init];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

-(void)trackApplicationOpen
{
    NSDictionary *info = [phs infoSDKSettings];
    
    if (info)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHPublisherOpenRequest requestForApp:info[@"Token"] secret:info[@"Secret"]] send]
        });
    }
    else
    {
        UE_LOG(LogPlayhaven, Log, TEXT("[Playhaven] was not found in info.plist tracking may not behave correctly"));
    }
}

-(NSDictionary *)infoSDKSettings
{
    return [[NSBundle mainBundle] infoDictionary][@"Playhaven"];
}

-(void)applicationDidFinishLaunching:(NSNotification *)n
{
    NSDictionary *dLaunchOptionsUrl = n.userInfo[@"UIApplicationLaunchOptionsURLKey"];
    
    if (!dLaunchOptionsUrl)
    {
        [phs trackApplicationOpen];
    }
}

-(void)applicationWillEnterForeground:(NSNotification *)n
{
    [phs trackApplicationOpen];
}


-(void)requestWillGetContent:(PHPublisherContentRequest *)request
{
}

-(void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    
}

-(void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content
{
    
}

-(void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content
{
    
}

-(void)requestContentDidDismiss:(PHPublisherContentRequest *)request DEPRECATED_ATTRIBUTE
{
    
}

-(void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type
{
    
}

-(void)request:(PHPublisherContentRequest *)request contentDidFailWithError:(NSError *)error DEPRECATED_ATTRIBUTE
{
    
}

-(UIImage *)request:(PHPublisherContentRequest *)request closeButtonImageForControlState:(UIControlState)state content:(PHContent *)content
{
    
}

-(UIColor *)request:(PHPublisherContentRequest *)request borderColorForContent:(PHContent *)content
{
    
}

-(void)request:(PHPublisherContentRequest *)request unlockedReward:(PHReward *)reward
{
    
}

-(void)request:(PHPublisherContentRequest *)request makePurchase:(PHPurchase *)purchase
{
    
}

@end

#endif

void UPlayhavenFunctions::PlayhavenContentRequest(FString placement, bool showsOverlayImmediately)
{
#if PLATFORM_IOS
    NSDictionary *d = [phs infoSDKSettings];
    
    if (d)
    {
        NSString *token  = d[@"Token"];
        NSString *secret = d[@"Secret"];
        
        PHPublisherContentRequest *r = [PHPublisherContentRequest requestForApp:token
                                                                         secret:secret
                                                                      placement:placement.GetNSString()
                                                                       delegate:phs];
        r.showsOverlayImmediately = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            [r send];
        });
    }
    
#elif PLATFORM_ANDROID
    static jmethodID Method = FJavaWrapper::FindMethod(Env,
                                                       FJavaWrapper::GameActivityClassID,
                                                       "AndroidThunkJava_PlayhavenContentRequest",
                                                       "(Ljava/lang/String;Z)V",
                                                       false);
    
    jstring  jPlacement               = Env->NewStringUTF(TCHAR_TO_UTF8(*placement));
    jboolean jShowsOverlayImmediately = (jboolean)ShowsOverlayImmediately;

    FJavaWrapper::CallVoidMethod(Env, FJavaWrapper::GameActivityThis, Method, jPlacement, jShowsOverlayImmediately);
    
    Env->DeleteLocalRef(jPlacement);
#endif
    
}

void UPlayhavenFunctions::PlayhavenContentRequestPreload(FString placement)
{
#if PLATFORM_IOS
    NSDictionary *d = [phs infoSDKSettings];
    
    if (d)
    {
        NSString *token  = d[@"Token"];
        NSString *secret = d[@"Secret"];
        
        PHPublisherContentRequest *r = [PHPublisherContentRequest requestForApp:token
                                                                         secret:secret
                                                                      placement:placement.GetNSString()
                                                                       delegate:phs];

        dispatch_async(dispatch_get_main_queue(), ^{
            [r preload];
        });
    }
    
#elif PLATFORM_ANDROID
    static jmethodID Method = FJavaWrapper::FindMethod(Env,
                                                       FJavaWrapper::GameActivityClassID,
                                                       "AndroidThunkJava_PlayhavenContentRequestPreload",
                                                       "(Ljava/lang/String;)V",
                                                       false);
    
    jstring jPlacement = Env->NewStringUTF(TCHAR_TO_UTF8(*placement));
    
    FJavaWrapper::CallVoidMethod(Env, FJavaWrapper::GameActivityThis, Method, jPlacement);
    
    Env->DeleteLocalRef(jPlacement);
#endif
    
}

void UPlayhavenFunctions::PlayhavenTrackPurchase(FString productID, int quantity, int resolution, FString receiptData)
{
#if PLATFORM_IOS
    NSDictionary *d = [phs infoSDKSettings];
    
    if (d)
    {
        NSString *token  = d[@"Token"];
        NSString *secret = d[@"Secret"];
    
        PHPublisherIAPTrackingRequest *r = [PHPublisherIAPTrackingRequest requestForApp:token
                                                                                 secret:secret
                                                                                product:productID
                                                                               quantity:quantity
                                                                             resolution:resolution
                                                                            receiptData:receiptData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [r send];
        });
    }
#elif PLATFORM_ANDROID

    static jmethodID Method = FJavaWrapper::FindMethod(Env,
                                                       FJavaWrapper::GameActivityClassID,
                                                       "AndroidThunkJava_PlayhavenTrackPurchase",
                                                       "(Ljava/lang/String;IILjava/lang/String;)V",
                                                       false);
    
    jstring jProductID   = Env->NewStringUTF(TCHAR_TO_UTF8(*productID));
    jint    jQuantity    = (jint)quantity;
    jint    jResolution  = (jint)resolution;
    jstring jReceiptData = Env->NewStringUTF(TCHAR_TO_UTF8(*receiptData));
    
    FJavaWrapper::CallVoidMethod(Env, FJavaWrapper::GameActivityThis, Method, jProductID, jQuantity, jResolution, jReceiptData);
    
    Env->DeleteLocalRef(jProductID);
    Env->DeleteLocalRef(jReceiptData);
#endif
}

void UPlayhavenFunctions::PlayhavenSetOptOutStatus(bool optOutStatus)
{
}
