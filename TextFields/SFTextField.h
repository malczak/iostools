//
//  SFTextField.h
//  EditableTextField
//
//  Created by malczak on 3/28/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    SFTextFieldLineHeightSpacing = 0,
    SFTextFieldLineAscenderSpacing,
    SFTextFieldLineTightSpacing,
    SFTextFieldLineExplicitSpacing,
} SFTextFieldLineSpacingType;

CGPathRef textToPath(NSString *string, UIFont *font, NSTextAlignment align, CGSize expectedSize, SFTextFieldLineSpacingType lineSpacingType, float lineSpacing);

@class SFTextField;

@protocol SFTextFieldDelegate

-(CGRect)textFieldWillStartEdit:(SFTextField*) textField;

-(void)textFieldWillEndEdit:(SFTextField*) textField;

-(void)textFieldDidChange:(SFTextField*) textField;

@end

@interface SFTextField : UIView <UITextViewDelegate> {
    
}

@property (nonatomic, assign) SFTextFieldLineSpacingType lineSpacingType;

@property (nonatomic, assign) float scale;

@property (nonatomic, readonly) BOOL editting;

@property (nonatomic, readonly, getter = getUnscaledBounds) CGRect unscaledBounds;

@property (nonatomic, retain) id<SFTextFieldDelegate> delegate;

@property(nonatomic, copy) NSString *placeholder;

-(UIBezierPath*) textPath;

-(CGRect)getCaretRect;

-(UIColor*) color;
-(void) setColor:(UIColor*)color;

-(NSString*)text;
-(void) setText:(NSString*)value;

-(UIFont*) font;
-(void) setFont:(UIFont *)font;

-(NSTextAlignment) textAlignment;
-(void) setTextAlignment:(NSTextAlignment)value;

@end
