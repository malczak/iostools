//
//  Orientation.c
//  captionizeit
//
//  Created by malczak on 6/7/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import "Orientation.h"
#import <Foundation/Foundation.h>

NSString *imageOrientationNameFromOrientation(UIImageOrientation orientation)
{
    NSArray *names = [NSArray
                      arrayWithObjects:
                      @"Up",
                      @"Down",
                      @"Left",
                      @"Right",
                      @"Up-Mirrored",
                      @"Down-Mirrored",
                      @"Left-Mirrored",
                      @"Right-Mirrored",
                      nil];
    return [names objectAtIndex:orientation];
}

UIImageOrientation currentImageOrientationWithMirroring(BOOL isUsingFrontCamera)
{
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    if( deviceOrientation == UIDeviceOrientationUnknown ) {
        switch ( [[UIApplication sharedApplication] statusBarOrientation] ) {
            case UIInterfaceOrientationPortrait           :
                deviceOrientation = UIDeviceOrientationPortrait;
                break;
            case UIInterfaceOrientationPortraitUpsideDown :
                deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft      :
                deviceOrientation = UIDeviceOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationLandscapeRight     :
                deviceOrientation = UIDeviceOrientationLandscapeLeft;
                break;
        }
    }
    
    switch (deviceOrientation)
    {
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationPortrait:
            return isUsingFrontCamera ? UIImageOrientationRight : UIImageOrientationLeftMirrored;
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortraitUpsideDown:
            return isUsingFrontCamera ? UIImageOrientationLeft :UIImageOrientationRightMirrored;
        case UIDeviceOrientationLandscapeLeft:
            return isUsingFrontCamera ? UIImageOrientationDown :  UIImageOrientationUpMirrored;
        case UIDeviceOrientationLandscapeRight:
            return isUsingFrontCamera ? UIImageOrientationUp : UIImageOrientationDownMirrored;
        default:
            return  UIImageOrientationUp;
    }
}

UIImageOrientation currentImageOrientation(BOOL isUsingFrontCamera, BOOL shouldMirrorFlip)
{
    if (shouldMirrorFlip)
        return currentImageOrientationWithMirroring(isUsingFrontCamera);
    
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    if( (deviceOrientation == UIDeviceOrientationUnknown)||
       (deviceOrientation == UIDeviceOrientationFaceUp)||
       (deviceOrientation == UIDeviceOrientationFaceDown) ) {
        switch ( [[UIApplication sharedApplication] statusBarOrientation] ) {
            case UIInterfaceOrientationPortrait           :
                deviceOrientation = UIDeviceOrientationPortrait;
                break;
            case UIInterfaceOrientationPortraitUpsideDown :
                deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft      :
                deviceOrientation = UIDeviceOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationLandscapeRight     :
                deviceOrientation = UIDeviceOrientationLandscapeLeft;
                break;
        }
    }
    
    switch (deviceOrientation)
    {
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationPortrait:
            return isUsingFrontCamera ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortraitUpsideDown:
            return isUsingFrontCamera ? UIImageOrientationRightMirrored :UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeLeft:
            return isUsingFrontCamera ? UIImageOrientationDownMirrored :  UIImageOrientationUp;
        case UIDeviceOrientationLandscapeRight:
            return isUsingFrontCamera ? UIImageOrientationUpMirrored :UIImageOrientationDown;
        default:
            return  UIImageOrientationUp;
    }
}

CGRect CGRectTransform(CGRect input, CGAffineTransform transform)
{
    float minx = CGRectGetMinX(input);
    float miny = CGRectGetMinY(input);
    
    float maxx = CGRectGetMaxX(input);
    float maxy = CGRectGetMaxY(input);
    
    CGPoint oMinP = CGPointApplyAffineTransform(CGPointMake(minx, miny), transform);
    CGPoint oMaxP = CGPointApplyAffineTransform(CGPointMake(maxx, maxy), transform);
    
    if(oMinP.x > oMaxP.x) {
        minx = oMaxP.x;
        maxx = oMinP.x;
    } else {
        minx = oMinP.x;
        maxx = oMaxP.x;
    }
    
    if(oMinP.y > oMaxP.y) {
        miny = oMaxP.y;
        maxy = oMinP.y;
    } else {
        miny = oMinP.y;
        maxy = oMaxP.y;
    }
    
    return CGRectMake(0, 0, maxx-minx, maxy-miny);
}


void getOrientationFixTransform(UIImage *image, CGAffineTransform *outTransform)
{
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    UIImageOrientation orient = image.imageOrientation;
    
    CGAffineTransform T = CGAffineTransformIdentity;
    
    switch (orient) {
        case UIImageOrientationUp: // EXIF 1
            break;
        case UIImageOrientationDown: // EXIF 3
            T = CGAffineTransformRotate(T, M_PI);
            break;
        case UIImageOrientationLeft: // EXIF 6
            T = CGAffineTransformRotate(T, M_PI/2.0);
            break;
        case UIImageOrientationRight: // EXIF 8
            T = CGAffineTransformRotate(T, 3.0*M_PI/2.0);
            break;
        case UIImageOrientationUpMirrored: // EXIF 2
            T = CGAffineTransformScale(T, -1, 1);
            break;
        case UIImageOrientationDownMirrored: // EXIF 4
            T = CGAffineTransformScale(T, 1, -1);
            break;
        case UIImageOrientationLeftMirrored: // EXIF 5
            T = CGAffineTransformScale(T, -1, 1);
            T = CGAffineTransformRotate(T, 3.0*M_PI/2.0);
            break;
        case UIImageOrientationRightMirrored: // EXIF 7
            T = CGAffineTransformScale(T, -1, 1);
            T = CGAffineTransformRotate(T, M_PI/2.0);
            break;
    }
    
    
    CGRect imageBounds = CGRectMake(0, 0, width, height);
    CGRect postRect = CGRectTransform(imageBounds, T);
    CGFloat newWidth = postRect.size.width;
    CGFloat newHeight = postRect.size.height;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(-width*0.5, -height*0.5) );
    transform = CGAffineTransformConcat(transform, T);
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1, -1));
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(newWidth*0.5, newHeight*0.5));
    
    *outTransform = transform;
}
