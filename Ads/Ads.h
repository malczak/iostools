//
//  Ads.h
//  captionizeit
//
//  Created by malczak on 6/7/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import "GADBannerView.h"
#import <iAd/iAd.h>
#import <Foundation/Foundation.h>

typedef enum {
    iAd,
    AdMob
} AdsProvider;

@protocol AdsDelegate

-(UIView*) adsGetRootView;

-(UIViewController*) adsGetRootController;

-(NSString*) adsGetIdForProvider:(AdsProvider) provider;

-(NSArray*) adsGetTestDevicesForProvider:(AdsProvider) provider;

-(void) adsPositionAdView:(UIView*) view ForProvider:(AdsProvider) provider;

@end

@interface Ads : NSObject <ADBannerViewDelegate, GADBannerViewDelegate>

@property (nonatomic, retain) id<AdsDelegate> delegate;

-(BOOL) isShowingAd;

-(void) createAdView;

-(void) removeAdView;

@end
