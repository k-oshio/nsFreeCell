//
//  CardView.h
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "Card.h"

@class GameController;

@interface CardView : NSView
{
	IBOutlet GameController	*control;
    NSMutableArray			*_cards;
}

- (void)addCard:(Card *)card facingUp:(BOOL)flag;
- (void)layoutCards;
- (NSImage *)imageForCards:(NSArray *)cardsToDrag dragOffset:(NSPoint *)dragOffset;
- (NSArray *)cardsForDragFromCard:(Card *)card index:(unsigned)dragIndex;
- (unsigned)count;
- (Card *)topCard;
- (void)removeTopCard;
- (void)removeAllCards;
- (BOOL)containsCardWithSuit:(SuitType)suit rank:(RankType)rank;
- (void)drawCardWell;

// Primitives.
- (void)removeCardsInArray:(NSArray *)cards;
- (void)addCardsFromArray:(NSArray *)cards;

@end
