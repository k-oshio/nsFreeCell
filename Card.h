//
//  Card.h
//  nsFreeCell
//
//  Created by kdyke on Mon Apr 09 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

#import <AppKit/AppKit.h>

typedef enum _SuitType {
    kHearts = 0,
    kSpades = 1,
    kDiamonds = 2,
    kClubs  = 3,
    kNumSuits,
} SuitType;

typedef enum _RankType {
    kJoker = 0,
    kAce = 1,
    kTwo = 2,
    kThree = 3,
    kFour = 4,
    kFive = 5,
    kSix = 6,
    kSeven = 7,
    kEight = 8,
    kNine = 9,
    kTen = 10,
    kJack = 11,
    kQueen = 12,
    kKing = 13,
    kHighAce = 14,
    kNumRanks,
} RankType;

typedef enum _ColorType {
    kRed = 0,
    kBlack = 1,
    kNumColors = 2,
} ColorType;

@interface Card : NSObject {
    RankType _rank;
    SuitType _suit;
    BOOL _isFacingUp;
    NSImage *_image;
    NSPoint _origin;
}

+ (NSSize)cardSize;
+ (void)generateGlyphInfo;
+ (NSImage *)iconImage;
+ (void)setControl:(id)control;

- initWithSuit:(SuitType)suit rank:(RankType)rank facingUp:(BOOL)flag;

- (id)control;
- (BOOL)isBlack;
- (BOOL)isRed;
- (RankType)rank;
- (SuitType)suit;
- (ColorType)color;
- (BOOL)isFacingUp;
- (void)setFacingUp:(BOOL)flag;
- (BOOL)containsPoint:(NSPoint)point;
- (NSImage *)image;

- (NSPoint)origin;
- (void)setOrigin:(NSPoint)origin;

- (void)drawAtPoint:(NSPoint)origin;
- (void)draw;

- (NSRect)bounds;
- (NSRect)srcRect;

@end

