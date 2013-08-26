//
//  SFTextView.h
//  captionizeit
//
//  Created by malczak on 4/29/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SFTextView : UIView <UITextViewDelegate, UITextInputTraits> {

}

@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) CGFloat maxFontSize;
@property (nonatomic, assign) CGFloat minFontSize;
@property (nonatomic, retain) NSString *placeholder;

-(BOOL) isEmpty;

-(UIView*) inputAccessoryView;
-(void) setInputAccessoryView:(UIView*)view;

-(UIColor*) color;
-(void) setColor:(UIColor*)color;

-(NSString*)text;
-(void) setText:(NSString*)value;

-(UIFont*) font;
-(void) setFont:(UIFont *)font;

-(NSTextAlignment) textAlignment;
-(void) setTextAlignment:(NSTextAlignment)value;

// UITextInputTraits
@property(nonatomic, getter = autocapitalizationType, setter =  setAutocapitalizationType:) UITextAutocapitalizationType autocapitalizationType;
/*
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UITextSpellCheckingType spellCheckingType;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic) BOOL enablesReturnKeyAutomatically;
*/


@end
