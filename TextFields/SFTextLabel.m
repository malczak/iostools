//
//  SFTextLabel.m
//  captionizeit
//
//  Created by malczak on 5/6/13.
//  Copyright (c) 2013 segfaultsoft. All rights reserved.
//

#import "SFTextLabel.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

static const float TEXT_SIZE = 22;

static const float TEXT_SIZE_MIN = 6;

static const float TEXT_SIZE_MAX = 30;



static const float MAX_TEXT_WIDTH = 310;

static const float TEXTVIEW_PADDING = 2;

#pragma mark Text to path creation

/*
 text to path coretext related ref :
 
 http://stackoverflow.com/questions/9976454/cgpathref-from-string
 
 https://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/CoreText_Programming/Operations/Operations.html#//apple_ref/doc/uid/TP40005533-CH4-SW18
 
 https://github.com/BigZaphod/Chameleon/blob/master/UIKit/Classes/UIStringDrawing.m
 
 https://github.com/ole/Animated-Paths/blob/master/Classes/AnimatedPathViewController.m
 */
static CGPathRef textToPath(NSString *string, UIFont *font, NSTextAlignment align, CGSize expectedSize, SFTextLabelLineSpacingType lineSpacingType, float lineSpacing)
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
        
        if(lineSpacingType == SFTextLabelLineHeightSpacing) {
            lineDelta += lineHeight;
        } else
            if(lineSpacingType == SFTextLabelLineAscenderSpacing) {
                lineDelta += lineAscent;
            } else
                if( lineSpacingType == SFTextLabelLineTightSpacing ) {
                    lineDelta += calculatedLineHeight;
                } else {
                    lineDelta += lineAscent * lineSpacing;
                }
        
        start += usedChars;
    }
    
    CGRect pathRect = CGPathGetBoundingBox(textPath);
    CGAffineTransform T = CGAffineTransformIdentity;
    //    T = CGAffineTransformScale(T, 1, -1);
    //    T = CGAffineTransformTranslate(T, 0, -pathRect.size.height);
    T = CGAffineTransformTranslate(T, -pathRect.origin.x, -pathRect.origin.y);
    CGPathRef output = CGPathCreateCopyByTransformingPath(textPath, &T);
    CGPathRelease(textPath);
    return output;
}

@interface SFTextLabel () {
    BOOL hasText;
    
    float textSize;
    
    UIColor *shadowColor;
    UIColor *textColor;
    
    CGSize expectedLabelSize;
    
    BOOL textLayerIsDirty;
    CGPathRef textPath;
    
    CALayer  *textLayer;
    CAShapeLayer *textContentLayer;
    CAShapeLayer *textShadowLayer;
}

@property (nonatomic, assign) float totalScale;

-(void) createChildren;

-(void) setTextLayerNeedsUpdate;
-(void) setTextBoundsNeedUpdate;

-(void) calculateSizeFromString:(NSString*)text withFont:(UIFont*) font;

@end

@implementation SFTextLabel

@synthesize textAlignment=_textAlignment, color=_color, text=_text, font=_font, scale=_scale, totalScale=_totalScale, lineSpacingType;

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
    self.lineSpacingType = SFTextLabelLineAscenderSpacing;
    
    textColor = [UIColor whiteColor];
    shadowColor = [UIColor blackColor];
    
    textSize = TEXT_SIZE;
    hasText = NO;
    
    self.layer.shouldRasterize = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.totalScale = 1;
    self.scale = 1;
    
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
    
    textLayerIsDirty = YES;
    
    [self setFont:[UIFont systemFontOfSize:12]];
    [self setText:@""];
}

-(void) calculateSizeFromString:(NSString*)text withFont:(UIFont*) font
{
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
        textSize = workingFontSize;
        _font = workingFont;
    }
    
    expectedLabelSize = calculatedLabelSize;
    
    CGSize finalSize = CGSizeMake(expectedLabelSize.width + TEXTVIEW_PAD2, expectedLabelSize.height + TEXTVIEW_PAD2);
    CGRect newBounds = (CGRect){ {0,0}, { finalSize.width*self.totalScale, finalSize.height*self.totalScale } };
    self.bounds = newBounds;
}

#pragma mark Draw rect

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    const float TEXTVIEW_PAD2 = TEXTVIEW_PADDING * 2;
    
    if(textLayerIsDirty) {
        
        if(textPath) {
            CGPathRelease(textPath);
        }

        textPath = textToPath(self.text,
                              self.font,
                              self.textAlignment,
                              expectedLabelSize,
                              self.lineSpacingType, 1.0);

        CGRect pathRect = CGPathGetPathBoundingBox(textPath);

        CGSize finalSize = CGSizeMake(pathRect.size.width + TEXTVIEW_PAD2, pathRect.size.height + TEXTVIEW_PAD2);
        CGRect newBounds = (CGRect){ {0,0}, { finalSize.width*self.totalScale, finalSize.height*self.totalScale } };
        self.bounds = newBounds;

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
    
}


#pragma mark Begin/End editting

-(UIBezierPath*) textPath
{
    UIBezierPath *outPath =  [[UIBezierPath alloc] init];
    outPath.CGPath = textPath;
    return outPath;
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

-(void)setFont:(UIFont *)font
{
    UIFont *fixedFont = [UIFont fontWithName:font.fontName size:textSize];
    _font = fixedFont;
    [self setTextLayerNeedsUpdate];
}

-(void) setTextAlignment:(NSTextAlignment)value
{
    _textAlignment = value;
    [self setTextLayerNeedsUpdate];
}

-(void) setText:(NSString*)value {
    _text = value;
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
    [self calculateSizeFromString:self.text withFont:self.font];
}

-(void)dealloc
{
    self.font = nil;
    self.text = nil;
}

@end