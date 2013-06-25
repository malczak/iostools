//
//  SFTextView.h
//  captionizeit
//
//  Created by malczak on 4/29/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SFTextView : UIView <UITextViewDelegate> {

}

@property (nonatomic, assign) CGFloat maxHeight;

//-(UIView*) inputAccessoryView;
//-(void) setInputAccessoryView:(UIView*)view;

-(UIColor*) color;
-(void) setColor:(UIColor*)color;

-(NSString*)text;
-(void) setText:(NSString*)value;

-(UIFont*) font;
-(void) setFont:(UIFont *)font;

-(NSTextAlignment) textAlignment;
-(void) setTextAlignment:(NSTextAlignment)value;

@end
