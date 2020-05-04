//
//  Card.m
//  nsFreeCell
//
//  Created by kdyke on Mon Apr 09 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

#import "Card.h"
#import <math.h>

#define CARD_CORNER_RADIUS 4.0f

#define CARD_HEIGHT	90.0f
#define CARD_ASPECT (2.5f / 3.5f)
#define CARD_WIDTH  (CARD_ASPECT * CARD_HEIGHT)

#define CARD_WIDTH_CENTER (CARD_WIDTH / 2.0f)

#define CARD_HEIGHT_CENTER (CARD_HEIGHT / 2.0f)

#define RANK_OFFSET_X 8.0f
#define RANK_OFFSET_Y 8.0f

#define RANK_SUIT_OFFSET_X_OUTER 20.0f
#define RANK_SUIT_OFFSET_Y_OUTER 19.0f
#define RANK_SUIT_OFFSET_Y_INNER 17.0f

#define RANK_SUIT_OFFSET_Y 9.0f

#define RANK_POINT_SIZE 12.0f
#define SMALL_POINT_SIZE 10.0f
#define MEDIUM_POINT_SIZE 20.0f
#define LARGE_POINT_SIZE 30.0f

static NSColor *_nsRedColor;
static NSColor *_nsBlackColor;
static id controlObj;

typedef enum _GlyphSize
{
    kSmallGlyph = 0,
    kMediumGlyph = 1,
    kLargeGlyph = 2,
    kNumGlyphSizes = 3,
} GlyphSize;

static NSFont *_rankFont;
static NSGlyph _rankGlyph[kNumRanks];

static NSFont *_suitFont[kNumSuits];
static NSGlyph _suitGlyph[kNumSuits];
static NSColor *_suitColor[kNumSuits];

// Pre-centered suit glyphs of various sizes.
static NSBezierPath *_suitGlyphPath[kNumSuits][kNumGlyphSizes];
static NSBezierPath *_rankGlyphPath[kNumRanks];

static unichar _suitCharacters[4] =
{
    0x2665,	// Heart
    0x2660, // Spade
    0x2666, // Diamond
    0x2663  // Club
};

static NSBezierPath *_cardPath;

@implementation Card

+ (void)setControl:(id)control
{
	controlObj = control;
}

- (id)control
{
	return controlObj;
}

+ (void)generateGlyphInfo
{
    int i, j;
    NSTextView *textView;
    NSLayoutManager *layoutManager;

    // The NSTextView is used purely for glyph generation. It handles all of the
    // work of building a functional NSText system for us.
    textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 128.0f, 128.0f)];
    layoutManager = [textView layoutManager];

// AmericanTypewriter-Regular not found in 10.1 ????
    // _rankFont = [NSFont fontWithName:@"AmericanTypewriter" size:RANK_POINT_SIZE];
    _rankFont = [NSFont fontWithName:@"Courier" size:RANK_POINT_SIZE];
    
    [textView setFont:_rankFont];
    [textView setString:@" A23456789 JQKA10"];
    for(i = kJoker; i <= kHighAce; i++)
        _rankGlyph[i] = [layoutManager glyphAtIndex:i];

    for(i = 0; i < kNumRanks; i++)
    {
        if(_rankGlyph[i])
        {
            NSRect glyphRect;
            NSPoint glyphCenter;
            
            glyphRect = [_rankFont boundingRectForGlyph:_rankGlyph[i]];
            glyphCenter = NSMakePoint(-NSMidX(glyphRect),-NSMidY(glyphRect));

            _rankGlyphPath[i] = [[NSBezierPath alloc] init];
            [_rankGlyphPath[i] moveToPoint:glyphCenter];
            [_rankGlyphPath[i] appendBezierPathWithGlyph:_rankGlyph[i]
                                    inFont:_rankFont];
        }
    }

    // Build "glyph path" for 10 card
    {
        NSGlyph one, zero;
        NSRect oneRect, zeroRect, rect;
        NSPoint oneCenter, zeroCenter, rectCenter;
        
        one = [layoutManager glyphAtIndex:15];
        oneRect = [_rankFont boundingRectForGlyph:one];

        zero = [layoutManager glyphAtIndex:16];
        zeroRect = [_rankFont boundingRectForGlyph:zero];

        // Whacked out math to try to stick the two glyphs right up
        // against each other and then center the result.
        zeroRect = NSOffsetRect(zeroRect,NSMaxX(oneRect) - NSMinX(zeroRect), 0.0f);
        rect = NSUnionRect(oneRect, zeroRect);
        
        rectCenter = NSMakePoint(NSMidX(rect), NSMidY(rect));
        oneCenter = NSMakePoint(-NSMidX(oneRect), -NSMidY(oneRect));
        zeroCenter = NSMakePoint(-NSMidX(zeroRect), -NSMidY(oneRect));

        _rankGlyphPath[kTen] = [[NSBezierPath alloc] init];
        [_rankGlyphPath[kTen] moveToPoint:
            NSMakePoint(-rectCenter.x, oneCenter.y)];
        [_rankGlyphPath[kTen] appendBezierPathWithGlyph:one
                                inFont:_rankFont];
        [_rankGlyphPath[kTen] moveToPoint:
            NSMakePoint(-rectCenter.x+NSMinX(zeroRect), zeroCenter.y)];
        [_rankGlyphPath[kTen] appendBezierPathWithGlyph:zero
                                inFont:_rankFont];
    }
    
    _suitFont[kSmallGlyph]  = [NSFont fontWithName:@"Symbol" size:SMALL_POINT_SIZE];
    _suitFont[kMediumGlyph] = [NSFont fontWithName:@"Symbol" size:MEDIUM_POINT_SIZE];
    _suitFont[kLargeGlyph]  = [NSFont fontWithName:@"Symbol" size:LARGE_POINT_SIZE];
    
    // Get glyph id's.  We currently assume that the glyph ids are the same for
    // all sizes of a font.
    [textView setFont:_suitFont[kSmallGlyph]];
    [textView setString:[NSString stringWithCharacters:_suitCharacters length:4]];

    // Construct suit glyphs
    for(i = 0; i < kNumSuits; i++)
    {
        _suitGlyph[i] = [layoutManager glyphAtIndex:i];
        for(j = 0; j < kNumGlyphSizes; j++)
        {
            NSRect glyphRect;
            NSPoint glyphCenter;
            
            glyphRect = [_suitFont[j] boundingRectForGlyph:_suitGlyph[i]];
            glyphCenter = NSMakePoint(-NSMidX(glyphRect),-NSMidY(glyphRect));

            _suitGlyphPath[i][j] = [[NSBezierPath alloc] init];
            [_suitGlyphPath[i][j] moveToPoint:glyphCenter];
            [_suitGlyphPath[i][j] appendBezierPathWithGlyph:_suitGlyph[i]
                                    inFont:_suitFont[j]];
        }
    }

    // Don't need this guy any more...

    _nsRedColor = [NSColor colorWithCalibratedRed:0.6f green:0.0f blue:0.0f alpha:1.0f];
    _nsBlackColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    
    _suitColor[kHearts]   = _nsRedColor;
    _suitColor[kSpades]   = _nsBlackColor;
    _suitColor[kDiamonds] = _nsRedColor;
    _suitColor[kClubs]    = _nsBlackColor;

    // Construct NSBezier path for card.
    _cardPath = [[NSBezierPath alloc] init];
    
    // Bottom left corner
    [_cardPath appendBezierPathWithArcWithCenter:
        NSMakePoint(CARD_CORNER_RADIUS,CARD_CORNER_RADIUS)
        radius:CARD_CORNER_RADIUS
        startAngle:180.0f
        endAngle:270.0f];

    // Bottom right corner
    [_cardPath appendBezierPathWithArcWithCenter:
        NSMakePoint(CARD_WIDTH - CARD_CORNER_RADIUS,CARD_CORNER_RADIUS)
        radius:CARD_CORNER_RADIUS
        startAngle:270.0f
        endAngle:0.0f];
    
    // Upper right corner
    [_cardPath appendBezierPathWithArcWithCenter:
        NSMakePoint(CARD_WIDTH - CARD_CORNER_RADIUS,CARD_HEIGHT - CARD_CORNER_RADIUS)
        radius:CARD_CORNER_RADIUS
        startAngle:0.0f
        endAngle:90.0f];
        
    // Upper left corner
    [_cardPath appendBezierPathWithArcWithCenter:
        NSMakePoint(CARD_CORNER_RADIUS,CARD_HEIGHT - CARD_CORNER_RADIUS)
        radius:CARD_CORNER_RADIUS
        startAngle:90.0f
        endAngle:180.0f];

    [_cardPath closePath];
    [_cardPath setLineWidth:0.5f];
}

// I'm not an artist, but I can at least make the computer 
// draw an app icon for me. ;)
+ (NSImage *)iconImage
{
    NSImage *image;
    CGContextRef ctx;
    
    image = [[NSImage alloc] init];
    [image setSize:NSMakeSize(128.0f, 128.0f)];
    
    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0.0f, 0.0f, 128.0f, 128.0f));
    ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    [_suitColor[kHearts] set];
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 32.0f, 96.0f);
    CGContextScaleCTM(ctx,2.0f,2.0f);
    [_suitGlyphPath[kHearts][kLargeGlyph] fill];
    CGContextRestoreGState(ctx);

    [_suitColor[kSpades] set];
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 96.0f, 96.0f);
    CGContextScaleCTM(ctx, 2.0f, 2.0f);
    [_suitGlyphPath[kSpades][kLargeGlyph] fill];
    CGContextRestoreGState(ctx);

    [_suitColor[kClubs] set];
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 32.0f, 32.0f);
    CGContextScaleCTM(ctx, 2.0f, 2.0f);
    [_suitGlyphPath[kClubs][kLargeGlyph] fill];
    CGContextRestoreGState(ctx);

    [_suitColor[kDiamonds] set];
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,96.0f,32.0f);
    CGContextScaleCTM(ctx,2.0f,2.0f);
    [_suitGlyphPath[kDiamonds][kLargeGlyph] fill];
    CGContextRestoreGState(ctx);
    
    [image unlockFocus];
    
    return image;
}

+ (NSSize)cardSize
{
    return NSMakeSize(CARD_WIDTH + 2.0f, CARD_HEIGHT + 2.0f);
}

- initWithSuit:(SuitType)suit rank:(RankType)rank facingUp:(BOOL)flag
{
    self = [super init];
    _suit = suit;
    _rank = rank;
    _isFacingUp = flag;
    _origin = NSMakePoint(0.0f, 0.0f);
    return self;
}


- (BOOL)isBlack
{
    return (_suit & 1) != 0;
}

- (BOOL)isRed
{
    return (_suit & 1) == 0;
}

- (RankType)rank
{
    return _rank;
}

- (SuitType)suit
{
    return _suit;
}

- (ColorType)color
{
    return (_suit & 1) ? kBlack : kRed;
}

- (BOOL)isFacingUp
{
    return _isFacingUp;
}

- (void)setFacingUp:(BOOL)flag	// ##undo
{
    [[[[self control] undoManager] prepareWithInvocationTarget:self]
		setFacingUp:_isFacingUp];
		_isFacingUp = flag;
}

// Hit detection
- (BOOL)containsPoint:(NSPoint)point
{
    return [_cardPath containsPoint:NSMakePoint(point.x - _origin.x,
                                                point.y - _origin.y)];
}

// Since each card requires a different placement, we just
// have explicit code for each layout.
// I really ought to just pre-build more NSBezier paths for each of these...it 
// would probably run a hell of a lot faster than pushing and popping graphics
// state over and over again.
void drawRankJoker(SuitType suit, CGContextRef ctx)
{
}

void drawRankAce(SuitType suit, CGContextRef ctx)
{
    // Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kLargeGlyph] fill];
    CGContextRestoreGState(ctx);
    
}


static void drawRankTwo(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT-RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx,-1.0f,-1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankThree(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT-RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankFour(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

}

static void drawRankFive(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

}

static void drawRankSix(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankSeven(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Upper Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        (CARD_HEIGHT_CENTER + CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER) * 0.5f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
        
    // Center left
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Center right
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankEight(SuitType suit, CGContextRef ctx)
{
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Upper Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        (CARD_HEIGHT_CENTER + CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER) * 0.5f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
        
    // Center left
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Center right
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        (CARD_HEIGHT_CENTER + RANK_SUIT_OFFSET_Y_OUTER) * 0.5f);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankNine(SuitType suit, CGContextRef ctx)
{
    // Upper
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Upper middle
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER - RANK_SUIT_OFFSET_Y_INNER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER - RANK_SUIT_OFFSET_Y_INNER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        CARD_HEIGHT_CENTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower middle
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER + RANK_SUIT_OFFSET_Y_INNER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER + RANK_SUIT_OFFSET_Y_INNER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

static void drawRankTen(SuitType suit, CGContextRef ctx)
{
    // Upper
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Upper Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        (CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER - RANK_SUIT_OFFSET_Y_INNER +
         CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER) * 0.5f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Upper middle
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER - RANK_SUIT_OFFSET_Y_INNER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        CARD_HEIGHT - RANK_SUIT_OFFSET_Y_OUTER - RANK_SUIT_OFFSET_Y_INNER);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower middle
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER + RANK_SUIT_OFFSET_Y_INNER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH-RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER + RANK_SUIT_OFFSET_Y_INNER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower Center
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH_CENTER,
        (RANK_SUIT_OFFSET_Y_OUTER + RANK_SUIT_OFFSET_Y_INNER +
         RANK_SUIT_OFFSET_Y_OUTER) * 0.5f);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    // Lower
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,
        CARD_WIDTH - RANK_SUIT_OFFSET_X_OUTER,
        RANK_SUIT_OFFSET_Y_OUTER);
    CGContextScaleCTM(ctx, -1.0f, -1.0f);
    [_suitGlyphPath[suit][kMediumGlyph] fill];
    CGContextRestoreGState(ctx);
}

// FIXME - Need some kind of nice face card rendering.  Mabye
// draw some PDFs or something.
static void drawRankJack(SuitType suit, CGContextRef ctx)
{
}

static void drawRankQueen(SuitType suit, CGContextRef ctx)
{
}

static void drawRankKing(SuitType suit, CGContextRef ctx)
{
}

static void (*drawRank[kNumRanks])(SuitType suit, CGContextRef ctx) =
{
    drawRankJoker,
    drawRankAce,
    drawRankTwo,
    drawRankThree,
    drawRankFour,
    drawRankFive,
    drawRankSix,
    drawRankSeven,
    drawRankEight,
    drawRankNine,
    drawRankTen,
    drawRankJack,
    drawRankQueen,
    drawRankKing,
    drawRankAce
};

- (void)renderAtPoint:(NSPoint)origin
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    // Card is actually inset a bit...
    CGContextTranslateCTM(ctx, origin.x + 1.0f, origin.y + 1.0f);
    
    // Begin by constructing card path outline.
    if(_isFacingUp)
    {
        [[NSColor whiteColor] set];
        [_cardPath fill];
        [[NSColor blackColor] set];
        [_cardPath stroke];

        // Handle common corner code... (broken for Joker cards)
        [_suitColor[_suit] set];    
        
        // Upper left
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx,
            RANK_OFFSET_X,
            CARD_HEIGHT-RANK_OFFSET_Y);
        [_rankGlyphPath[_rank] fill];
        CGContextTranslateCTM(ctx,
            0,
            -RANK_SUIT_OFFSET_Y);
        [_suitGlyphPath[_suit][kSmallGlyph] fill];    
        CGContextRestoreGState(ctx);
    
        // Upper right
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx,
            CARD_WIDTH - RANK_OFFSET_X,
            CARD_HEIGHT-RANK_OFFSET_Y);
        [_rankGlyphPath[_rank] fill];
        CGContextTranslateCTM(ctx, 0, -RANK_SUIT_OFFSET_Y);
        [_suitGlyphPath[_suit][kSmallGlyph] fill];    
        CGContextRestoreGState(ctx);
    
        // Lower left
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx,
            RANK_OFFSET_X,
            RANK_OFFSET_Y);
        CGContextScaleCTM(ctx, -1.0f, -1.0f);
        [_rankGlyphPath[_rank] fill];
        CGContextTranslateCTM(ctx,
            0,
            -RANK_SUIT_OFFSET_Y);
        [_suitGlyphPath[_suit][kSmallGlyph] fill];    
        CGContextRestoreGState(ctx);
    
        // Lower right
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx,
            CARD_WIDTH - RANK_OFFSET_X,
            RANK_OFFSET_Y);
        CGContextScaleCTM(ctx,-1.0f,-1.0f);
        [_rankGlyphPath[_rank] fill];
        CGContextTranslateCTM(ctx,
            0,
            -RANK_SUIT_OFFSET_Y);
        [_suitGlyphPath[_suit][kSmallGlyph] fill];    
        CGContextRestoreGState(ctx);
        
        // Do custom center drawing
        (drawRank[_rank])(_suit, ctx);
    }
    else
    {
        [[NSColor blueColor] set];
        [_cardPath fill];
        [[NSColor blackColor] set];
        [_cardPath stroke];    
    }
    
    CGContextRestoreGState(ctx);
}

// Generate 
- (NSImage *)image
{
  if(!_image)
  {
    NSSize size = [_cardPath bounds].size;
    _image = [[NSImage alloc] init];
    // We allow an extra pixel around each edge
    size = NSMakeSize(size.width + 2.0f, size.height + 2.0f);
    [_image setSize:size];
    [_image lockFocus];
    [self renderAtPoint:NSMakePoint(0.0f, 0.0f)];
    [_image unlockFocus];
  }
  return _image;
}

- (NSRect)bounds
{
    return NSMakeRect(_origin.x, _origin.y, CARD_WIDTH + 2.0f, CARD_HEIGHT + 2.0f);
}

- (NSRect)srcRect
{
    return NSMakeRect(0, 0, CARD_WIDTH + 2.0f, CARD_HEIGHT + 2.0f);
}

- (void)draw
{
    [self drawAtPoint:_origin];
}

- (void)drawAtPoint:(NSPoint)origin
{	
  if([[NSGraphicsContext currentContext] isDrawingToScreen])
//    [[self image] compositeToPoint:origin operation:NSCompositeSourceOver];
    [[self image] drawAtPoint:origin fromRect:[self srcRect] operation:NSCompositeSourceOver fraction:1.0];
  else
    [self renderAtPoint:_origin];
}

- (void)setOrigin:(NSPoint)origin
{
    _origin = origin;
}

- (NSPoint)origin
{
    return _origin;
}

@end
