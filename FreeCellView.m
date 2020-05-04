//
//  FreeCellView.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import "FreeCellView.h"
#import "GameController.h"
#import "Card.h"

@implementation FreeCellView

- (void)awakeFromNib
{	
    NSRect rect;
    rect.origin = NSMakePoint(0.0f, 0.0f);
    rect.size = [Card cardSize];
    rect = NSIntegralRect(rect);
    [self setFrameSize:rect.size];
}

- (NSArray *)cardsForDragFromCard:(Card *)card index:(unsigned)dragIndex
{
    // We always let the user drag the one card we hold.
    if([_cards count])
        return [NSArray arrayWithObject:[_cards objectAtIndex:0]];
    return nil;
}

// See if we can accept the card(s) being dragged.
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *draggedCards = [control cardsBeingDragged];
	id		source = [control dragSource];

	// exclude drag to self (to avoid undo problem)
	if (source == self) return NO;

    // Free cells can accept any single card.
    if([_cards count] == 0 && [draggedCards count] == 1)
    {
        return YES;
    }
    return NO;
}

- (void)drawRect:(NSRect)rect
{
    [self drawCardWell];
    [super drawRect:rect]; 
}

@end
