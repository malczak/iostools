//
//  SFTextView.m
//  captionizeit
//
//  Created by malczak on 4/29/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SFTextView.h"

static const float TEXT_SIZE_MIN = 6;

static const float TEXT_SIZE_MAX = 30;

static const float MAX_TEXT_WIDTH = 310;

static const float TEXTVIEW_PADDING = 8;

@interface SFTextView () {
    BOOL hasText;

    float textSize;

    CGSize calculatedTextSize;
    UITextView *textView;
    UIView *background;
}

-(void) createChildren;

@end

@implementation SFTextView

@synthesize maxHeight, maxWidth, maxFontSize, minFontSize, placeholder;
@synthesize autocapitalizationType;

-(id)init
{
    self = [super init];
    if(self) {
        [self createChildren];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self createChildren];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createChildren];
    }
    return self;
}

-(void)createChildren
{
//    self.backgroundColor = [UIColor clearColor];

    self.placeholder = @"ENTER TEXT";
    self.maxWidth = MAX_TEXT_WIDTH;
    self.maxFontSize = TEXT_SIZE_MAX;
    self.minFontSize = TEXT_SIZE_MIN;
    
    if(!textView) {
        textView = [[UITextView alloc] init];
        [self addSubview:textView];
        
        textView.layer.shouldRasterize = NO;
        textView.layer.shadowColor = [[UIColor blackColor] CGColor];
        textView.layer.shadowOffset = CGSizeMake(0,0);
        textView.layer.shadowOpacity = 1;
        textView.layer.shadowRadius = 2;
        
        textView.textColor = [UIColor whiteColor];
        textView.autoresizingMask = UIViewAutoresizingNone;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        textView.delegate = self;
        textView.clipsToBounds = YES;
        textView.scrollEnabled = NO;
        textView.editable = YES;
        textView.hidden = NO;
        textView.userInteractionEnabled = NO;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.transform = CGAffineTransformIdentity;
        textView.backgroundColor = [UIColor clearColor];
    }

    if(!background) {
        background = [[UIView alloc] init];
        [self insertSubview:background atIndex:0];
        background.userInteractionEnabled = NO;
        background.layer.cornerRadius = 4;
        background.backgroundColor = [UIColor blackColor];
        background.alpha = 0.4;
        background.hidden = YES;
    }
    
    hasText = NO;
    [self setupState];
}

-(BOOL)becomeFirstResponder {
    textView.userInteractionEnabled = YES;
    textView.editable = YES;
    return [textView becomeFirstResponder];
}

-(BOOL)resignFirstResponder {
    textView.userInteractionEnabled = NO;
    textView.editable = NO;
    return [textView resignFirstResponder];
}

-(BOOL)canBecomeFirstResponder {
    return [textView canBecomeFirstResponder];
}

-(BOOL)canResignFirstResponder {
    return [textView canResignFirstResponder];
}

-(BOOL)isFirstResponder {
    return [textView isFirstResponder];
}

#pragma mark Text size calculation


-(CGSize) calculateSizeFromString:(NSString*)text withFont:(UIFont*) font
{
    if([text length] == 0) {
        return CGSizeZero;
    }
    
    const float TEXTVIEW_PAD2 = TEXTVIEW_PADDING * 2;
    const float MAX_WIDTH = self.maxWidth - TEXTVIEW_PAD2;
    
    CGSize calculatedLabelSize;
    BOOL finished = NO;
    
    float workingFontSize = self.maxFontSize;
    UIFont* workingFont = [UIFont fontWithName:font.fontName size:workingFontSize];
    
    do{
        
        finished= YES;
        
        CGSize maximumLabelSize = CGSizeMake(9999,9999);
        
        if(IOS7) {
            NSStringDrawingContext *ctx = [[NSStringDrawingContext alloc] init];
            ctx.minimumScaleFactor = 0.1;
            NSDictionary *attrs = @{
                                    NSFontAttributeName: workingFont
                                    };
            CGRect bounds = [text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:ctx];
            calculatedLabelSize = bounds.size;
        } else {
            calculatedLabelSize = [text sizeWithFont:workingFont
                                   constrainedToSize:maximumLabelSize
                                       lineBreakMode:NSLineBreakByWordWrapping];            
        }
        
        if( (calculatedLabelSize.width > MAX_WIDTH) && (workingFontSize>self.minFontSize) ) {
            workingFontSize -= 1;
            workingFont = [UIFont fontWithName:font.fontName size:workingFontSize];
            finished = NO;
        }
        
    }while(finished==NO);
    
    if(workingFont!=font) {
        textView.font = workingFont;
        textSize = workingFontSize;
    }
    
    float h = calculatedLabelSize.height;
    
    unichar lastChar = [text characterAtIndex:[text length]-1];
    
    if( (lastChar == (short)'\r') || (lastChar == (short)'\n') ) {
        h += font.lineHeight;
    }
    
    calculatedTextSize = CGSizeMake(calculatedLabelSize.width + TEXTVIEW_PAD2, h + TEXTVIEW_PAD2);

    [self setCalculatedFrameSize];
    
    return calculatedTextSize;
}

-(void) setCalculatedFrameSize
{
    CGFloat finalHeight = (maxHeight>0) ? fminf(maxHeight - textView.scrollIndicatorInsets.top - textView.scrollIndicatorInsets.bottom,calculatedTextSize.height) : calculatedTextSize.height;
    CGSize finalSize = CGSizeMake(calculatedTextSize.width, finalHeight);
    CGRect finalRect =  (CGRect){ {0,0}, finalSize };
    
    background.frame = finalRect;
    textView.bounds = finalRect;
    textView.frame = finalRect;
    
    self.bounds = finalRect;    
}

-(void) setupState
{
    if(![self isFirstResponder]) {
        hasText = (textView.hasText)&&(![textView.text isEqualToString:self.placeholder]);
        if(!hasText) {
            textView.alpha = 0.6;
            textView.text = placeholder;
        } else {
            textView.alpha = 1.0;
        }
    }
    [self calculateSizeFromString:self.text withFont:self.font];
}


#pragma mark Begin/End editting

-(void)textViewDidBeginEditing:(UITextView *)view
{
    [self setNeedsDisplay];
    if([self isEmpty]) {
        textView.text = @"";
        textView.alpha = 1.0;
    }
    background.hidden = NO;
}

-(void)textViewDidEndEditing:(UITextView *)view
{
    background.hidden = YES;
    textView.editable = NO;
    hasText = textView.hasText;
    [self setupState];
}

-(BOOL)textView:(UITextView *)view shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *currentText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self calculateSizeFromString:currentText withFont:textView.font];
    return YES;
}

-(void)textViewDidChangeSelection:(UITextView *)textView
{
}

-(void)textViewDidChange:(UITextView *)textView
{
}

-(UIColor*) color
{
    return textView.textColor;
}

-(void) setColor:(UIColor*)color
{
    textView.textColor = color;
}

-(UIFont*) font;
{
    return textView.font;
}

-(void)setFont:(UIFont *)font
{
    UIFont *fixedFont = [UIFont fontWithName:font.fontName size:textSize];
    
    textView.font = fixedFont;
    [self setupState];
}

-(NSTextAlignment) textAlignment
{
    return textView.textAlignment;
}

-(void) setTextAlignment:(NSTextAlignment)value
{
    textView.textAlignment = value;
    [self setupState];
}

-(NSString*)text {
    return textView.text;
}

-(void) setText:(NSString*)value {
    textView.text = value;
    [self setupState];
}

-(UIView*) inputAccessoryView
{
    return (nil!=textView.inputAccessoryView)?textView.inputAccessoryView:nil;
}

-(void) setInputAccessoryView:(UIView*)view
{
    textView.inputAccessoryView = view;
}

-(BOOL) isEmpty {
    return (NO==hasText);
}

-(void)setMaxHeight:(CGFloat)value
{
    maxHeight = value;
    [self setCalculatedFrameSize];
}

#pragma mark UITextInputTraits properties
-(UITextAutocapitalizationType)autocapitalizationType {
    return textView.autocapitalizationType;
}

-(void)setAutocapitalizationType:(UITextAutocapitalizationType)value {
    textView.autocapitalizationType = value;
}

/*
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UITextSpellCheckingType spellCheckingType;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic) BOOL enablesReturnKeyAutomatically;
*/

-(void)dealloc
{
    self.inputAccessoryView = nil;
//    [self setInputAccessoryView:nil];
}

@end
