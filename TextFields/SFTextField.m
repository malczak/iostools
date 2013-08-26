//
//  SFTextField.m
//  EditableTextField
//
//  Created by malczak on 3/28/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import "SFTextField.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

static const float TEXT_SIZE = 22;

static const float TEXT_SIZE_MIN = 6;

static const float TEXT_SIZE_MAX = 30;



static const float MAX_TEXT_WIDTH = 310;

static const float TEXTVIEW_PADDING = 8;

#pragma mark Text to path creation

/*
 text to path coretext related ref :

 http://stackoverflow.com/questions/9976454/cgpathref-from-string
 
 https://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/CoreText_Programming/Operations/Operations.html#//apple_ref/doc/uid/TP40005533-CH4-SW18

 https://github.com/BigZaphod/Chameleon/blob/master/UIKit/Classes/UIStringDrawing.m
 
 https://github.com/ole/Animated-Paths/blob/master/Classes/AnimatedPathViewController.m
 */
CGPathRef textToPath(NSString *string, UIFont *font, NSTextAlignment align, CGSize expectedSize, SFTextFieldLineSpacingType lineSpacingType, float lineSpacing)
{
    CGMutablePathRef textPath = CGPathCreateMutable();

    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)font, kCTFontAttributeName,
                           nil];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attrs];
    CFAttributedStringRef ctAttributesString = (__bridge CFAttributedStringRef)attributedString;
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(ctAttributesString);
    
    const CFIndex stringLength = CFAttributedStringGetLength(ctAttributesString);
    
    const CGFloat lineHeight = font.lineHeight;
    const CGFloat lineAscent = font.ascender;
    
    float lineDelta  = lineHeight;
    
    CFIndex start = 0;
    
    while( start < stringLength ) {
        CFIndex usedChars = CTTypesetterSuggestLineBreak(typesetter, start, MAX_TEXT_WIDTH);
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedChars));
        if(!line) {
            CGPathRelease(textPath);
            return NULL;
        }
        
        float flush;
        switch (align) {
            case NSTextAlignmentCenter:	flush = 0.5;	break;
            case NSTextAlignmentRight:	flush = 1;		break;
            case NSTextAlignmentLeft:
            default:					flush = 0;		break;
        }
        
        CGFloat calculatedLineHeight = 0;
        
        CGFloat penOffset = CTLineGetPenOffsetForFlush(line, flush, expectedSize.width);
        
        CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
        CFIndex runIdx = 0;
        CFIndex runCnt = CFArrayGetCount(glyphRuns);
        
        while(runIdx<runCnt) {
            
            CTRunRef lineRun = CFArrayGetValueAtIndex(glyphRuns, runIdx);
            
            CFIndex glyphIdx = 0;
            CFIndex glyphCnt = CTRunGetGlyphCount(lineRun);
            
            
            while( glyphIdx < glyphCnt ) {
                
                CGGlyph glyph;
                CGPoint position;
                
                CFRange thisGlyphRange = CFRangeMake(glyphIdx, 1);
                CTRunGetGlyphs(lineRun, thisGlyphRange, &glyph);
                CTRunGetPositions(lineRun, thisGlyphRange, &position);
                
                CGAffineTransform T = CGAffineTransformMakeScale(1, -1);
                CGPathRef letterPath = CTFontCreatePathForGlyph(ctFont, glyph, &T);
                T = CGAffineTransformMakeTranslation(position.x + penOffset, position.y + lineDelta);
                CGPathAddPath(textPath, &T, letterPath);

                CGRect letterRect = CGPathGetPathBoundingBox(letterPath);
                calculatedLineHeight = fmaxf( CGRectGetHeight(letterRect), calculatedLineHeight );
                
                CGPathRelease(letterPath);
                
                glyphIdx += 1;
            }
            
            
            runIdx += 1;
        }

//        CFRelease(glyphRuns);
//        CFRelease(line);
        
        if(lineSpacingType == SFTextFieldLineHeightSpacing) {
            lineDelta += lineHeight;
        } else
            if(lineSpacingType == SFTextFieldLineAscenderSpacing) {
                lineDelta += lineAscent;
            } else
                if( lineSpacingType == SFTextFieldLineTightSpacing ) {
                    lineDelta += calculatedLineHeight;
                } else {
                    lineDelta += lineAscent * lineSpacing;
                }
        
        start += usedChars;
    }
    
//    CGRect pathRect = CGPathGetBoundingBox(textPath);
    CGAffineTransform T = CGAffineTransformIdentity;
//    T = CGAffineTransformScale(T, 1, -1);
//    T = CGAffineTransformTranslate(T, 0, -pathRect.size.height);
//    T = CGAffineTransformTranslate(T, -pathRect.origin.x, -pathRect.origin.y);
    T = CGAffineTransformTranslate(T, 8, 0);
    CGPathRef output = CGPathCreateCopyByTransformingPath(textPath, &T);
    CGPathRelease(textPath);
    return output;
}

#pragma mark SFTextField implementation

@interface SFTextField () {
    BOOL hasText;
    
    float textSize;
    
    UIColor *shadowColor;
    UIColor *textColor;
    
    UITextView *textView;
    UIView *background;
    
    CGSize expectedLabelSize;

    BOOL textLayerIsDirty;
    CGPathRef textPath;
    
    CALayer  *textLayer;
    CAShapeLayer *textContentLayer;
    CAShapeLayer *textShadowLayer;

    CGAffineTransform displayTransform;
    float displayScale;
    
    UITapGestureRecognizer *recognizer;
    UITapGestureRecognizer *parentTapRecognizer;
}

@property (nonatomic, assign) float totalScale;

-(void) createChildren;

-(void) handleTapGesture:(UIGestureRecognizer*) recognizer;
-(void) handleParentTapGesture:(UIGestureRecognizer*) recognizer;

-(void) setTextLayerNeedsUpdate;
-(void) setTextBoundsNeedUpdate;

-(CGSize) calculateSizeFromString:(NSString*)text withFont:(UIFont*) font;

@end

@implementation SFTextField

@synthesize editting=_editting, placeholder, unscaledBounds, delegate, scale=_scale, totalScale=_totalScale, lineSpacingType;

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
    self.lineSpacingType = SFTextFieldLineAscenderSpacing;
    
    textColor = [UIColor whiteColor];
    shadowColor = [UIColor blackColor];
    
    textSize = TEXT_SIZE;
    
    placeholder = @"Enter text";
    
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    recognizer.cancelsTouchesInView = YES;
//    [self addGestureRecognizer:recognizer];
    
//    self.layer.anchorPoint = (CGPoint) {0,0};
    self.layer.shouldRasterize = NO;
    self.backgroundColor = [UIColor clearColor];
    
    self.totalScale = 1;
    self.scale = 1;
    _editting = NO;
    hasText = NO;
    
    textView = [[UITextView alloc] init];
    [self addSubview:textView];
    textView.layer.shadowColor = [[UIColor blackColor] CGColor];
    textView.layer.shadowOffset = CGSizeMake(0,0);
    textView.layer.shadowOpacity = 1;
    textView.layer.shadowRadius = 4;
//    textView.layer.masksToBounds = YES;
    
    // text & shadow rendering layers
    textLayer = [[CALayer alloc] init];
    textLayer.opacity = 1.0;
    textLayer.shouldRasterize = false;
    [self.layer addSublayer:textLayer];
    
    textContentLayer = [[CAShapeLayer alloc] init];
    textContentLayer.opacity = 1;
    textContentLayer.shouldRasterize = false;
    [textLayer insertSublayer:textContentLayer atIndex:0];
    
    textShadowLayer = [[CAShapeLayer alloc] init];
    textShadowLayer.opacity = 0.6;
    textShadowLayer.shouldRasterize = false;
    const float shadow_alpha = 45.0 * M_PI / 180.0;
    textShadowLayer.position = CGPointMake( cosf(shadow_alpha), sinf(shadow_alpha) );
    [textLayer insertSublayer:textShadowLayer atIndex:0];
    
    textView.textColor = [UIColor whiteColor];
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.delegate = self;
    textView.clipsToBounds = NO;
    textView.scrollEnabled = YES;
    textView.editable = NO;
    textView.hidden = YES;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.transform = CGAffineTransformIdentity;
    textView.backgroundColor = [UIColor clearColor];
    textView.layer.shouldRasterize = NO;
    
    background = [[UIView alloc] init];
    [self insertSubview:background atIndex:0];
    background.userInteractionEnabled = NO;
    background.layer.cornerRadius = 4;
    background.backgroundColor = [UIColor blackColor];
    background.alpha = 0.4;
    background.hidden = YES;
    
    textLayerIsDirty = YES;
    
    [self setText:placeholder];
}

-(CGSize) calculateSizeFromString:(NSString*)text withFont:(UIFont*) font
{
    if([text length] == 0) {
        return CGSizeZero;
    }
    
    const float TEXTVIEW_PAD2 = TEXTVIEW_PADDING * 2;
    const float MAX_WIDTH = MAX_TEXT_WIDTH - TEXTVIEW_PAD2;
    
    CGSize calculatedLabelSize;
    BOOL finished = NO;
    
    float workingFontSize = TEXT_SIZE_MAX;
    UIFont* workingFont = [UIFont fontWithName:font.fontName size:workingFontSize];
    
    do{
        
        finished= YES;
        
        CGSize maximumLabelSize = CGSizeMake(9999,9999);
        
        calculatedLabelSize = [text sizeWithFont:workingFont
                             constrainedToSize:maximumLabelSize
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        if( (calculatedLabelSize.width > MAX_WIDTH) && (workingFontSize>TEXT_SIZE_MIN) ) {
            workingFontSize -= 1;
            workingFont = [UIFont fontWithName:font.fontName size:workingFontSize];
            finished = NO;
        }
        
    }while(finished==NO);
    
    if(workingFont!=font) {
        textView.font = workingFont;
        textSize = workingFontSize;
    }
    
    
    expectedLabelSize = calculatedLabelSize;
    
    
    float h = expectedLabelSize.height;
    
    unichar lastChar = [text characterAtIndex:[text length]-1];

    if( (lastChar == (short)'\r') || (lastChar == (short)'\n') ) {
        h += font.lineHeight;
    }
    
    CGSize finalSize = CGSizeMake(expectedLabelSize.width + TEXTVIEW_PAD2, h + TEXTVIEW_PAD2);
    CGRect finalRect =  (CGRect){ {0,0}, finalSize };
    
    background.frame = finalRect;
    textView.frame = finalRect;

    if(NO==self.editting) {
        CGRect newBounds = (CGRect){ {0,0}, { finalSize.width*self.totalScale, finalSize.height*self.totalScale } };
        self.bounds = newBounds;
    } else {
        self.bounds = finalRect;
    }

//    self.bounds = finalRect;
    
    return finalSize;
}


#pragma mark Draw rect

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if(textLayerIsDirty) {
        
        if(textPath) {
            CGPathRelease(textPath);
        }
        
        textPath = textToPath(textView.text, textView.font, textView.textAlignment, expectedLabelSize, self.lineSpacingType, 1.0);
        
        textContentLayer.path = textPath;
        textContentLayer.fillColor = [textColor CGColor];
        
        textShadowLayer.path = textPath;
        textShadowLayer.fillColor = [shadowColor CGColor];
        textShadowLayer.shadowColor = [shadowColor CGColor];
        textShadowLayer.shadowOffset = CGSizeMake(0, 0);
        textShadowLayer.shadowOpacity = 1;
        textShadowLayer.shadowPath = textPath;
        textShadowLayer.shadowRadius = 2;
       
        textLayerIsDirty = NO;
    }
    
//    return;
    
    if(NO==self.editting)
    {
        
//        CGContextScaleCTM(ctx, 1, -1);
//        CGContextTranslateCTM(ctx, 0, -textView.bounds.size.height);
        
        CGContextSaveGState(ctx);
        CGRect drawRect = self.bounds;
        
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.4);
        CGContextAddRect(ctx, drawRect);
        CGContextFillPath(ctx);
        
        drawRect = CGRectInset(drawRect, 8*self.totalScale, 8*self.totalScale);
        
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.4);
        CGContextAddRect(ctx, drawRect);
        CGContextFillPath(ctx);

        CGContextSetRGBFillColor(ctx, 0.0, 1.0, 0.0, 0.2);
        CGContextAddRect(ctx, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
        CGContextFillPath(ctx);

        CGContextRestoreGState(ctx);
      
        
        
/*        return;
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 0.0, 1.0);
      
        CGContextScaleCTM(ctx, self.totalScale, self.totalScale);

        CGRect pathRect = CGPathGetBoundingBox(textPath);
        
//        CGContextScaleCTM(ctx, 1, -1);
//        CGContextTranslateCTM(ctx, 0, -pathRect.size.height);
        [textLayer renderInContext:ctx];
        [textLayer drawInContext:ctx];

        CGContextSetTextPosition(ctx, 0, 0);
        
        // draw text path
        CGContextSaveGState(ctx);
        
        CGSize offset = CGSizeMake(2, 2);
        CGContextSetShadowWithColor(ctx, offset, 0, [[UIColor blueColor] CGColor]);


//        CGRect pathRect = CGPathGetBoundingBox(textPath);

//        CGContextScaleCTM(ctx, 1, -1);
//        CGContextTranslateCTM(ctx, 0, -pathRect.size.height);
        
        CGContextTranslateCTM(ctx, 8, -8 );
        
        CGContextAddPath(ctx, textPath);
        
        CGContextFillPath(ctx);
        
        CGContextRestoreGState(ctx);
       

        // if there's a shadow, let's set that up
//        CGSize offset = CGSizeMake(2, 2);
//        CGContextSetShadowWithColor(ctx, offset, 4, [[UIColor blueColor] CGColor]);
        
//        [textView.text drawInRect:drawRect withFont:self.font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentLeft];
*/
    }
}


#pragma mark Begin/End editting

-(void)textViewDidBeginEditing:(UITextView *)view
{
    [self setNeedsDisplay];
    background.hidden = NO;
    
    if(!hasText) {
        textView.text = @"";
    }
    
    if(self.superview) {
        parentTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleParentTapGesture:)];
        [self.superview addGestureRecognizer:parentTapRecognizer];
    }
    
    
    displayTransform = self.transform;
    displayScale = self.totalScale;
    
    CGRect editingPosition = self.frame;
    if(self.delegate) {
        editingPosition = [self.delegate textFieldWillStartEdit:self];
    }
    
    if(!CGAffineTransformEqualToTransform(displayTransform, CGAffineTransformIdentity)) {
        [UIView animateWithDuration:0.4
                         animations:^(void) {
                             self.transform = CGAffineTransformIdentity;
                             self.frame = editingPosition;
                         }
                         completion:^(BOOL finished) {
                             textView.hidden = NO;
                             textLayer.hidden = YES;
                             _editting = YES;

                             if(self.delegate) {
                                 [self.delegate textFieldDidChange:self];
                             }

                             [self setNeedsDisplay];
                         }];
    }
    
}

-(void)textViewDidEndEditing:(UITextView *)view
{
    background.hidden = YES;
    textView.editable = NO;
    textView.hidden = YES;
    textLayer.hidden = NO;
    hasText = textView.hasText;

    if(self.delegate) {
        [self.delegate textFieldWillEndEdit:self];
    }

    if(self.superview) {
        [self.superview removeGestureRecognizer:parentTapRecognizer];
        [parentTapRecognizer removeTarget:self action:@selector(handleParentTapGesture:)];
        parentTapRecognizer = nil;
    }
    
    assert(parentTapRecognizer==nil);

    
    _editting = NO;
    [textView resignFirstResponder];
    
    if(!textView.hasText) {
        [self setText:placeholder];
    } else {
        [self setTextLayerNeedsUpdate];
    }
    

    if(!CGAffineTransformEqualToTransform(displayTransform, CGAffineTransformIdentity)) {
        [UIView animateWithDuration:0.4
                         animations:^(void) {
                             self.transform = displayTransform;
                         }
                         completion:^(BOOL finished) {
                             [self setNeedsDisplay];
                         }];
    }
}

-(BOOL)textView:(UITextView *)view shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *currentText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self calculateSizeFromString:currentText withFont:textView.font];
    return YES;
}

-(void)textViewDidChangeSelection:(UITextView *)textView
{
    if(self.delegate) {
        [self.delegate textFieldDidChange:self];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    if(self.delegate) {
        [self.delegate textFieldDidChange:self];
    }
}

-(void)handleTapGesture:(UIGestureRecognizer *)recognizer
{
    if([textView isFirstResponder]) {
        return;
    }
    if(![textView canBecomeFirstResponder]) {
        return;
    }
    textView.editable = YES;
    [textView becomeFirstResponder];
}

-(void) handleParentTapGesture:(UIGestureRecognizer*) recognizer
{
    if([textView isFirstResponder]) {
        [textView resignFirstResponder];
    }
    [self resignFirstResponder];
}

-(UIBezierPath*) textPath
{
    UIBezierPath *outPath =  [[UIBezierPath alloc] init];
    outPath.CGPath = textPath;
    return outPath;
}

-(CGRect)getCaretRect
{
    if(!self.editting) {
        return CGRectZero;
    }
    UITextRange* selectionRange = textView.selectedTextRange;
    if(!selectionRange) {
        return CGRectZero;
    }
    CGRect selectionRect = [textView caretRectForPosition:selectionRange.start];
    return selectionRect;
}

-(CGRect)getUnscaledBounds
{
    CGRect rect = (CGRect){ {0,0}, textView.bounds.size };
    return rect;
}

-(UIColor*) color
{
    return textColor;
}

-(void) setColor:(UIColor*)color
{
    textColor = color;
    textContentLayer.fillColor = [color CGColor];
}

-(UIFont*) font;
{
    return textView.font;
}

-(void)setFont:(UIFont *)font
{
    UIFont *fixedFont = [UIFont fontWithName:font.fontName size:textSize];
    
    textView.font = fixedFont;
    textView.scrollEnabled = NO;

    [self setTextLayerNeedsUpdate];
}

-(NSTextAlignment) textAlignment
{
    return textView.textAlignment;
}

-(void) setTextAlignment:(NSTextAlignment)value
{
    textView.textAlignment = value;
    
    [self setTextLayerNeedsUpdate];
}

-(NSString*)text {
    return textView.text;
}

-(void) setText:(NSString*)value {
    textView.text = value;
    [self setTextLayerNeedsUpdate];
}

-(float)scale
{
    return _scale;
}

-(void)setScale:(float)value
{
    
    float newTotalScale = fmaxf( 0.01, fminf(10, self.totalScale * value));
//    float pointSize = self.font.pointSize * value;
    if( fabsf(self.totalScale-newTotalScale)<0.01) {
        return;
    }
    
    self.totalScale = newTotalScale;
    
    _scale = value;
    
    
    [CATransaction begin];
    
    //This is what prevents all animation during the transaction
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    CATransform3D T = textLayer.transform;
    T = CATransform3DScale(T, self.scale, self.scale, 1);
    textLayer.transform = T;// CATransform3DMakeScale(self.totalScale, self.totalScale, 1);
    
    [CATransaction commit];

    
//    self.font = [UIFont fontWithName:self.font.fontName size:pointSize];
    [self setTextBoundsNeedUpdate];
}

-(float)totalScale
{
    return _totalScale;
}

-(void)setTotalScale:(float)value
{
    _totalScale = value;
    [self setNeedsDisplay];
}

-(void) setTextLayerNeedsUpdate
{
    textLayerIsDirty = YES;
    [self setNeedsDisplay];
    [self setTextBoundsNeedUpdate];
}

-(void) setTextBoundsNeedUpdate
{
    [self calculateSizeFromString:textView.text withFont:textView.font];
}

-(void)dealloc
{
    self.font = nil;
    self.delegate = nil;
}

@end
