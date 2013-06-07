//
//  CaptureManager.h
//  DayByDay
//
//  Created by malczak on 11/12/12.
//  Copyright (c) 2012 segfaultsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CaptureManagerDeletegate <NSObject>

@optional

-(void) captureManagerDeviceHasChanged;

@end

@interface CaptureManager : NSObject {
 
    AVCaptureDevice *frontCameraDevice;
    AVCaptureDevice *backCameraDevice;
    AVCaptureDevice *activeDevice;
}

@property (nonatomic, retain) id<CaptureManagerDeletegate> delegate;
@property (nonatomic, assign, readonly) BOOL hasFrontCamera;
@property (nonatomic, assign, readonly) BOOL hasBackCamera;


@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, readonly, getter = getCaptureDevice) AVCaptureDevice *captureDevice;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillOuput;

-(BOOL) hasTwoVideoDevices;
-(BOOL) hasAnyVideoDevice;
-(BOOL) shouldFlipSceenshot;

-(BOOL) hasFlash;
-(BOOL) isFlashTurnedOn;
-(BOOL) turnFlash:(BOOL) on;

-(void) captureStillImage:(void(^)(UIImage* image))caputeCallback;

-(void) createVideoInput;
-(void) createVideoPreviewLayer;
-(void) setActiveDevice:(AVCaptureDevice*) device;
-(void) switchDevice;
-(void) start;
-(void) stop;


@end
