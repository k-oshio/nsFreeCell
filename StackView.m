//
//  StackView.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import "StackView.h"
#import "Card.h"
#import "GameController.h"

@implementation StackView

- (void)layoutCards
{
    int i, count;
    NSPoint origin;
    NSSize cardSize;
    NSRect bounds;
    
    cardSize = [Card cardSize];
    bounds = [self bounds];
    origin.x = 2.0f;
    origin.y = bounds.size.height - cardSize.height;
    
    count = [_cards count];
    for (i = 0; i < count; i++) {
        [[_cards objectAtIndex:i] setOrigin:origin];
        origin.y -= 20.0f;
    }
    [self setNeedsDisplay:YES];
}

- (NSArray *)cardsForDragFromCard:(Card *)card index:(unsigned)dragIndex
{
    NSMutableArray *array = nil;
    unsigned i, count, total, freeCells;
  
    // If only one card (the last one) is being dragged, let it go...
    if (dragIndex == ([_cards count] - 1)) {
        return [NSArray arrayWithObject:card];
	}
        
    // We have to see if there are enough free cells.  We need one free
    // cell for every card beyond one that we are dragging.
    count = [_cards count];
    total = count - dragIndex;
    
    freeCells = [control freeCellsNotIncludingView:nil];
    
    if (freeCells >= (total - 1)) {
        BOOL okayToDrag = YES;
        Card *card;
        RankType rank;
        ColorType color;
        
        // Now we have to make sure the rank/color test holds for all of
        // the cards being dragged.
        card = [_cards objectAtIndex:dragIndex];
        rank = [card rank];
        color = [card color];
        
        for (i = dragIndex + 1; i < count; i++) {
            rank--;
            color = (color == kRed) ? kBlack : kRed;
            card = [_cards objectAtIndex:i];
            if ([card rank] != rank ||
               [card color] != color) {
                okayToDrag = NO;
                break;
            }
        }
        
        if (okayToDrag) {
            array = [NSMutableArray arrayWithCapacity:total];
            for (i = dragIndex; i < count; i++) {
                [array addObject:[_cards objectAtIndex:i]];
            }
        }
    }
    return array;
}

// See if we can accept the card(s) being dragged.
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *draggedCards = [control cardsBeingDragged];
	id		source = [control dragSource];

    Card *lastCardOnStack, *firstCardBeingDragged;
        
	// exclude drag to self (to avoid undo problem)
	if (source == self) return NO;

    // Number of free cells not including this one must be >=
    // total cards being dragged - 1;
    if ([control freeCellsNotIncludingView:self] >= ([draggedCards count] - 1)) {
        lastCardOnStack = [_cards lastObject];
        
        // If we don't have any cards then we can accept as many as
        // can be dragged.
        if (!lastCardOnStack) return YES;
        
        firstCardBeingDragged = [draggedCards objectAtIndex:0];
        
        // Card color must not match and rank must be +1
        if ([firstCardBeingDragged color] != [lastCardOnStack color] &&
			([firstCardBeingDragged rank]+1) == [lastCardOnStack rank]) {
            return YES;
        }
    }
    return NO;    
}

@end
