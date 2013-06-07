//
//  Orientation.h
//  captionizeit
//
//  Created by malczak on 6/7/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#ifndef captionizeit_Orientation_h
#define captionizeit_Orientation_h

#import <Foundation/Foundation.h>

NSString *imageOrientationNameFromOrientation(UIImageOrientation orientation);

UIImageOrientation currentImageOrientation(BOOL isUsingFrontCamera, BOOL shouldMirrorFlip);

UIImageOrientation currentImageOrientationWithMirroring(BOOL isUsingFrontCamera);

void getOrientationFixTransform(UIImage *image, CGAffineTransform *outTransform);


#endif
