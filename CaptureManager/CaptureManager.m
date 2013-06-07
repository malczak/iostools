//
//  CaptureManager.m
//  DayByDay
//
//  Created by malczak on 11/12/12.
//  Copyright (c) 2012 segfaultsoft. All rights reserved.
//

#import "CaptureManager.h"
#import "Orientation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation CaptureManager {}

@synthesize captureSession;
@synthesize captureDevice;
@synthesize previewLayer;
@synthesize hasBackCamera, hasFrontCamera;

-(id) init
{
    self = [super init];
    if(self) {
        self.captureSession = [[AVCaptureSession alloc] init];
        frontCameraDevice = nil;
        backCameraDevice = nil;
        
        hasBackCamera = NO;
        hasFrontCamera = NO;

        NSArray *devices = [AVCaptureDevice devices];
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType:AVMediaTypeVideo]) {
                if ([device position] == AVCaptureDevicePositionBack) {
                    backCameraDevice = device;
                    hasBackCamera = true;
                } else {
                    frontCameraDevice = device;
                    hasFrontCamera = true;
                }
            }
        }
        
        
        self.stillOuput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillOuput setOutputSettings:options];
        
        if( [self.captureSession canAddOutput:self.stillOuput] ) {
            [self.captureSession addOutput:self.stillOuput];
        }
        
    }
    return self;
}

-(AVCaptureDevice*) getCaptureDevice {
    return activeDevice;
}

-(BOOL) hasTwoVideoDevices
{
    return hasFrontCamera && hasBackCamera;
}

-(BOOL) hasAnyVideoDevice
{
    return hasFrontCamera || hasBackCamera;
}

-(BOOL) shouldFlipSceenshot
{
    return [self hasTwoVideoDevices]&&(activeDevice!=nil)&&(activeDevice==frontCameraDevice);
}


-(BOOL) hasFlash
{
    if(self.captureSession && activeDevice) {
        return [activeDevice hasFlash];
    }
    return NO;
}

-(BOOL) isFlashTurnedOn
{
    return (activeDevice!=nil) && ( ([activeDevice flashMode] == AVCaptureFlashModeOn) || ([activeDevice flashMode] == AVCaptureFlashModeAuto) );
}

-(BOOL) turnFlash:(BOOL) on
{
    if([self hasFlash]) {
        NSError *error;
        if( [activeDevice lockForConfiguration:&error] ) {
            if(on) {
                [activeDevice setFlashMode:AVCaptureFlashModeOn];
            } else {
                [activeDevice setFlashMode:AVCaptureFlashModeOff];
            }
            
            [activeDevice unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

- (AVCaptureVideoOrientation)getCaptureOrientation
{
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
    
    if (deviceOrientation == UIDeviceOrientationPortrait)
        orientation = AVCaptureVideoOrientationPortrait;
    else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
        orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    
    // AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
    else if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
        orientation = AVCaptureVideoOrientationLandscapeRight;
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
        orientation = AVCaptureVideoOrientationLandscapeLeft;
    
    // Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
    
    return orientation;
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}

-(void) captureStillImage:(void(^)(UIImage* image))caputeCallback;
{
    if(self.captureSession && [self hasAnyVideoDevice] && self.stillOuput) {
        AVCaptureConnection *captureConnection = [self connectionWithMediaType:AVMediaTypeVideo
                                                               fromConnections:self.stillOuput.connections];
        
        
        //AVCaptureVideoOrientation videoOrientation = [self getCaptureOrientation];
        
        if([captureConnection isVideoOrientationSupported]) {
            [captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        [self.stillOuput captureStillImageAsynchronouslyFromConnection:captureConnection
                                                     completionHandler:
        ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if(imageDataSampleBuffer != NULL) {
                
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *tmpImg =  [[UIImage alloc] initWithData:imageData];
                
                BOOL usingFront = [self hasFrontCamera] && (activeDevice == frontCameraDevice);
                UIImageOrientation orientation = currentImageOrientation( usingFront, NO );//usingFront && [self shouldFlipSceenshot]);
                
                //                UIImage *image = tmpImg;//[[UIImage alloc] initWithCGImage:tmpImg.CGImage scale:1 orientation:orientation];
                UIImage *image = [[UIImage alloc] initWithCGImage:tmpImg.CGImage scale:1 orientation:orientation];
                
                /*
                if([self shouldFlipSceenshot]) {
                    //http://stackoverflow.com/questions/5505422/iphone-mirroring-back-a-picture-taken-from-the-front-camera/5505950#5505950
                    CGSize imageSize = image.size;
                    UIGraphicsBeginImageContextWithOptions(imageSize, YES, 1.0);
                    CGContextRef ctx = UIGraphicsGetCurrentContext();
                    CGContextRotateCTM(ctx, M_PI/2);
                    CGContextTranslateCTM(ctx, 0, -imageSize.width);
                    CGContextScaleCTM(ctx, imageSize.height/imageSize.width, imageSize.width/imageSize.height);
                    CGContextDrawImage(ctx, CGRectMake(0.0, 0.0, imageSize.width, imageSize.height), image.CGImage);
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                */
                if(caputeCallback) {
                    caputeCallback(image);
                }
                
                // save to lib
                /*
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:[image imageOrientation] completionBlock:
                 ^(NSURL *assetUrl, NSError *error) {
                     if(caputeCallback) {
                         caputeCallback(image);
                     }
                 }];
                library = nil;
                */
                
                image = nil;
                imageData = nil;
                
            }
        }];
        
    }
}

-(void) createVideoInput
{
    if(self.captureSession && [self hasAnyVideoDevice]) {
        
        AVCaptureDevice *videoDevice = backCameraDevice;
        
        if(videoDevice) {
            
                [self setActiveDevice:videoDevice];

        } else {
            NSLog(@"error on getting video device");
        }
    }
}

-(void) createVideoPreviewLayer
{
    if(self.captureSession && [self hasAnyVideoDevice]) {
        
        AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        self.previewLayer = videoPreviewLayer;
        
    }
}

-(void) setActiveDevice:(AVCaptureDevice*) device
{
    if(self.captureSession) {
        
        if(activeDevice) {
            AVCaptureDeviceInput *activeInput = nil;
            for (AVCaptureDeviceInput *input in self.captureSession.inputs) {
                if( input.device == activeDevice ) {
                    activeInput = input;
                    break;
                }
            }
            if(activeInput) {
                [self.captureSession removeInput:activeInput];
            }
            
        }
        
        NSError *error;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        
        if(!error) {

            if( [self.captureSession canAddInput:deviceInput] ) {
            
                [self.captureSession addInput:deviceInput];
                
                activeDevice = device;
                
                if([device lockForConfiguration:&error]) {

                    if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                    }
                    
                    
                    [device unlockForConfiguration];
                    
                    [self.captureSession beginConfiguration];
                    if([self.captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
                        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
                    } else {
                        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
                    }
                    [self.captureSession commitConfiguration];
                }
                
                if( [self.delegate respondsToSelector:@selector(captureManagerDeviceHasChanged)] ) {
                    [self.delegate captureManagerDeviceHasChanged];            
                }
                
                
            } else {
                NSLog(@"error on addInput");
            }
            
        } else {
            NSLog(@"error on create deviceInput");
        }
        
 
        
    }
}

-(void) switchDevice
{
    if(self.captureSession && [self hasTwoVideoDevices]) {
        AVCaptureDevice *newDevice = (activeDevice == frontCameraDevice)?backCameraDevice:frontCameraDevice;
        [self setActiveDevice:newDevice];
    }

}

-(void) start
{
    if(captureSession) {
        if(NO==captureSession.isRunning) {
            [captureSession startRunning];
            previewLayer.hidden = NO;
        }
    }
}

-(void) stop
{
    if(captureSession) {
        if(captureSession.isRunning) {
            [captureSession stopRunning];
            previewLayer.hidden = YES;
        }
    }
}

-(void) dealloc
{
    self.delegate = nil;
    [self stop];
    captureSession = nil;
}



@end
