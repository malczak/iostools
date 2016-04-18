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
    
    BOOL isLoadingAd;
    
    // iAd
    ADBannerView *iAdBannerView;
    
    // adMob
    GADBannerView *gAdBannerView;

}

-(void) createIAdBannerView;

-(void) removeIAdBannerView;

-(void) showIAdBannedView;

-(void) hideIAdBannerView;

-(void) createGAdBannerView;

-(void) removeGAdBannerView;

-(void) loadGAdBannerView;

-(void) showGAdBannedView;

-(void) hideGAdBannerView;

@end

@implementation Ads

@synthesize delegate;

-(BOOL) isShowingAd {
    return isPresentingAd;
}

-(void) createAdView{
    [self createIAdBannerView];
    [self createGAdBannerView];
    isLoadingAd = NO;
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
}   

-(void)removeIAdBannerView
{
    [self hideIAdBannerView];
    [iAdBannerView removeFromSuperview];
    iAdBannerView.delegate = nil;
    iAdBannerView = nil;
}

-(void) showIAdBannedView
{
    isPresentingAd = YES;
    iAdBannerView.hidden = NO;
    UIView *view = [delegate adsGetRootView];
    if(view && ![view.subviews containsObject:iAdBannerView]) {
        [view addSubview:iAdBannerView];
    }
}

-(void) hideIAdBannerView
{
    isPresentingAd = NO;
    iAdBannerView.hidden = YES;
    [iAdBannerView removeFromSuperview];
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
    if(!isPresentingAd) {
        [self hideGAdBannerView];
        [self showIAdBannedView];
        
        [self.delegate adsPositionAdView:iAdBannerView ForProvider:iAd];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {

#ifdef DEBUG
    NSLog(@"bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error %@",[error description]);
#endif
    [self hideIAdBannerView];
    // try gad
    [self loadGAdBannerView];
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
    gAdBannerView.hidden = YES;
    gAdBannerView.delegate = self;
    [[delegate adsGetRootView] addSubview:gAdBannerView];
}

-(void) loadGAdBannerView
{
    if(isLoadingAd) {
        return;
    }
    GADRequest *request = [GADRequest request];
    
#ifdef DEBUG
    NSArray *testDevices = [self.delegate adsGetTestDevicesForProvider:AdMob];
    if(testDevices && [testDevices count]) {
        request.testDevices = testDevices;
    }
#endif

    [gAdBannerView loadRequest:request];
    gAdBannerView.hidden = YES;
    isLoadingAd = YES;
}

-(void) showGAdBannedView
{
    isPresentingAd = YES;
    gAdBannerView.hidden = NO;
    UIView *view = [delegate adsGetRootView];
    if(view && ![view.subviews containsObject:gAdBannerView]) {
        [view addSubview:gAdBannerView];
    }
}

-(void) hideGAdBannerView
{
    isPresentingAd = NO;
    gAdBannerView.hidden = YES;
    [gAdBannerView removeFromSuperview];
}

-(void)removeGAdBannerView {
    [self hideGAdBannerView];
    gAdBannerView.rootViewController = nil;
    gAdBannerView.delegate = nil;
    gAdBannerView = nil;
}

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    
#ifdef DEBUG
    NSLog(@"adViewDidReceiveAd:(GADBannerView *)view");
#endif
    isLoadingAd = NO;
    if(!isPresentingAd) {
        [self hideIAdBannerView];
        [self showGAdBannedView];
        
        [self.delegate adsPositionAdView:gAdBannerView ForProvider:AdMob];
    }
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    
#ifdef DEBUG
    NSLog(@"adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error %@",[error description]);
#endif
    isLoadingAd = NO;
    [self hideGAdBannerView];
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
    
    [self hideIAdBannerView];
    [self hideGAdBannerView];
    
    [self removeIAdBannerView];
    [self removeGAdBannerView];
}

@end
