//
//  HomeView.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import "HomeView.h"
#import "GameController.h"
#import "Card.h"

@implementation HomeView

- (void)awakeFromNib
{	
    NSRect rect;
    rect.origin = NSMakePoint(0.0f,0.0f);
    rect.size = [Card cardSize];
    rect = NSIntegralRect(rect);
    [self setFrameSize:rect.size];
}

// See if we can accept the card(s) being dragged.
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *draggedCards = [control cardsBeingDragged];
    Card *draggedCard;
    Card *lastCardOnStack;
    
    // We can only accept one card at a time.
    if([draggedCards count] != 1)
        return NO;
    
    draggedCard = [draggedCards objectAtIndex:0];
    
    // If we don't have any cards and card is an ace, we can accept it.
    if([_cards count] == 0)
    {
        if([draggedCard rank] == kAce)
            return YES;
    }
    else // If suit matches and rank is one higher than topmost rank, we
         // can accept it.
    {
        lastCardOnStack = [_cards lastObject];
        if([draggedCard suit] == [lastCardOnStack suit] &&
           ([lastCardOnStack rank]+1) == [draggedCard rank])
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
