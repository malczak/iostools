//
//  SFTextLabel.h
//  captionizeit
//
//  Created by malczak on 5/6/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    SFTextLabelLineHeightSpacing = 0,
    SFTextLabelLineAscenderSpacing,
    SFTextLabelLineTightSpacing,
    SFTextLabelLineExplicitSpacing,
} SFTextLabelLineSpacingType;

@interface SFTextLabel : UIView


@property (nonatomic, assign) SFTextLabelLineSpacingType lineSpacingType;

@property (nonatomic, assign) float scale;

@property (nonatomic, assign) NSTextAlignment textAlignment;

@property (nonatomic, retain) UIFont *font;

@property (nonatomic, retain) NSString *text;

@property (nonatomic, retain) UIColor *color;

-(UIBezierPath*) textPath;

@end
