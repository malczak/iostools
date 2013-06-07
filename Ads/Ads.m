//
//  Ads.m
//  captionizeit
//
//  Created by malczak on 6/7/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import "Ads.h"

@interface Ads() {
    
    BOOL isPresentingAd;
    
    // iAd
    ADBannerView *iAdBannerView;
    
    // adMob
    GADBannerView *gAdBannerView;

}

-(void) createIAdBannerView;

-(void) removeIAdBannerView;

-(void) createGAdBannerView;

-(void) removeGAdBannerView;

@end

@implementation Ads

@synthesize delegate;

-(BOOL) isShowingAd {
    return isPresentingAd;
}

-(void) createAdView{
    [self createIAdBannerView];
}

-(void) removeAdView{
    [self removeGAdBannerView];
    [self removeIAdBannerView];
}


#pragma mark iAd delegate implementation

-(void) createIAdBannerView
{
    if(nil==delegate) {
        return;
    }
    iAdBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    iAdBannerView.hidden = YES;
    iAdBannerView.delegate = self;
    [[delegate adsGetRootView] addSubview:iAdBannerView];
    isPresentingAd = true;
}

-(void)removeIAdBannerView
{
    if(nil!=iAdBannerView) {
        iAdBannerView.delegate = nil;
        [iAdBannerView removeFromSuperview];
        iAdBannerView = nil;
    }
    isPresentingAd = false;
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
#ifdef DEBUG
    NSLog(@"bannerViewWillLoadAd:(ADBannerView *)banner");
#endif
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {

#ifdef DEBUG
    NSLog(@"bannerViewDidLoadAd:(ADBannerView *)banner");
#endif
    
    isPresentingAd = YES;
    iAdBannerView.hidden = NO;
    [self.delegate adsPositionAdView:iAdBannerView ForProvider:iAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {

#ifdef DEBUG
    NSLog(@"bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error %@",[error description]);
#endif
    
    [self removeIAdBannerView];
    
    // try gad
    [self createGAdBannerView];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
#ifdef DEBUG
    NSLog(@"bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave");
#endif
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
#ifdef DEBUG
    NSLog(@"bannerViewActionDidFinish:(ADBannerView *)banner");
#endif
}

#pragma mark AdMob delegate implementation
-(void) createGAdBannerView
{
    if(nil==delegate) {
        return;
    }
    
    gAdBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    gAdBannerView.adUnitID = [self.delegate adsGetIdForProvider:AdMob];
    gAdBannerView.rootViewController = [self.delegate adsGetRootController];
    gAdBannerView.delegate = self;
    gAdBannerView.hidden = YES;

    
    GADRequest *request = [GADRequest request];
    
#ifdef DEBUG
    NSArray *testDevices = [self.delegate adsGetTestDevicesForProvider:AdMob];
    if(testDevices && [testDevices count]) {
        request.testDevices = testDevices;
    }
#endif
    
    [gAdBannerView loadRequest:request];
    
    [[delegate adsGetRootView] addSubview:gAdBannerView];
    isPresentingAd = true;
}

-(void)removeGAdBannerView {
    if(nil!=gAdBannerView) {
        gAdBannerView.rootViewController = nil;
        gAdBannerView.delegate = nil;
        [gAdBannerView removeFromSuperview];
        gAdBannerView = nil;
    }
    isPresentingAd = false;
}

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    
#ifdef DEBUG
    NSLog(@"adViewDidReceiveAd:(GADBannerView *)view");
#endif
    
    isPresentingAd = YES;
    
    gAdBannerView.hidden = NO;
    [self.delegate adsPositionAdView:gAdBannerView ForProvider:AdMob];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    
#ifdef DEBUG
    NSLog(@"adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error %@",[error description]);
#endif
    
    [self removeGAdBannerView];
    
    //try iAd once again
    [self createIAdBannerView];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
#ifdef DEBUG
    NSLog(@"adViewWillPresentScreen:(GADBannerView *)adView");
#endif
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
#ifdef DEBUG
    NSLog(@"adViewWillDismissScreen:(GADBannerView *)adView");
#endif
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
#ifdef DEBUG
    NSLog(@"adViewDidDismissScreen:(GADBannerView *)adView");
#endif
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
#ifdef DEBUG
    NSLog(@"adViewWillLeaveApplication:(GADBannerView *)adView");
#endif
}

#pragma mark dealloc

-(void)dealloc
{
    delegate = nil;
}

@end
