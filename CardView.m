//
//  CardView.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import "CardView.h"
#import "Card.h"
#import "GameController.h"
#include <sys/time.h>

@implementation CardView

static NSColor *_darkGreenColor;
static NSColor *_greenColor;
static NSColor *_lightGreenColor;

+(void)initialize
{
    _darkGreenColor = [NSColor colorWithCalibratedRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
    _greenColor = [NSColor colorWithCalibratedRed:0.3f green:0.3f blue:0.3f alpha:1.0f];
    _lightGreenColor = [NSColor colorWithCalibratedRed:0.4f green:0.4f blue:0.4f alpha:1.0f];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    // Cards are stored from bottom to top (rendering order).
    _cards = [[NSMutableArray alloc] init];
    [self registerForDraggedTypes:[NSArray arrayWithObject:@"Cards"]];

    return self;
}

- (void)drawCardWell
{
    NSRect bounds = [self bounds];
    [_greenColor set];
    NSRectFill(bounds);
    [_lightGreenColor set];
    // Right/bottom edges
    NSRectFill(NSMakeRect(NSMaxX(bounds)-1.0f,0.0f,1.0f,bounds.size.height-1));
    NSRectFill(NSMakeRect(bounds.origin.x+1.0f,0.0f,bounds.size.width-1.0f,1.0f));
    // Left/top edges
    [_darkGreenColor set];
    NSRectFill(NSMakeRect(0.0f,1.0f,1.0f,bounds.size.height-1));
    NSRectFill(NSMakeRect(bounds.origin.x+1.0f,NSMaxY(bounds)-1.0f,bounds.size.width-1.0f,1.0f));
}


- (unsigned)count
{
    return [_cards count];
}

// Adds a card to the top of the stack.  Generates undo.
- (void)addCard:(Card *)card facingUp:(BOOL)flag
{
    [card setFacingUp:flag];
    [self addCardsFromArray:[NSArray arrayWithObject:card]];
}

- (Card *)topCard
{
    return [_cards lastObject];
}

// Removes the top card.  Does generate undo.
- (void)removeTopCard
{
    Card	*card = [_cards lastObject];
    [self removeCardsInArray:[NSArray arrayWithObject:card]];
}

// Used for clearing out all cards.  Does not generate any undo events.
- (void)removeAllCards
{
    [_cards removeAllObjects];
}

// Layout cards for rendering.  Subclasses may override this.
- (void)layoutCards
{
    int		i, count;
    count = [_cards count];
    for (i = 0; i < count; i++) {
        [[_cards objectAtIndex:i] setOrigin:NSMakePoint(0.0f, 0.0f)];
    }
}

- (BOOL)containsCardWithSuit:(SuitType)suit rank:(RankType)rank
{
    int		i, count;
    Card	*card;

    count = [_cards count];
    
    for (i = 0; i < count; i++) {
        card = [_cards objectAtIndex:i];
        if([card rank] == rank && [card suit] == suit)
            return YES;
    }
    return NO;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPasteboard *pboard;
	Card *card = nil, *temp;
	NSImage *dragImage;
	NSPoint mouseLocation;
	NSArray *cardsToDrag = nil;
	int i;
	unsigned dragIndex = 0xffffffff;

	mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];

	// Do hit detection from top down....
	for (i = [_cards count] - 1; i >= 0; i--) {
		temp = [_cards objectAtIndex:i];
		if ([temp containsPoint:mouseLocation]) {
			card = temp;
			dragIndex = i;
			break;
		}
	}

	if (card) {
		cardsToDrag = [self cardsForDragFromCard:card index:dragIndex];
	}

	if (cardsToDrag) {
		NSPoint dragOffset;
		dragImage = [self imageForCards:cardsToDrag dragOffset:&dragOffset];

		pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		[pboard declareTypes:[NSArray arrayWithObject:@"Cards"] owner:self];

		// Note: We don't really pass the cards around on the pasteboard since
		// that would be fairly clumsy.  Instead we simply keep track of them
		// internally.
		[pboard setData:[NSData data] forType:@"Cards"];

		// Use the window delegate, which will be the game controller.
		[control setCardsBeingDragged:cardsToDrag source:self];
  // ### depricated -> use beginDraggingSessionWith...      
		[self dragImage:dragImage at:dragOffset        
				offset:NSMakeSize(0.0f,0.0f)
				event:event
				pasteboard:pboard
				source:self
				slideBack:NO];
		[control updateGame];
	}
}

- (NSImage *)imageForCards:(NSArray *)cardsToDrag dragOffset:(NSPoint *)dragOffset
{
    // Get origin of first card.
    NSPoint			baseOrigin = [[cardsToDrag objectAtIndex:0] origin];
    NSRect			totalBounds;
    NSImage			*image;
    Card			*card;
    int				i, count;
    CGContextRef	ctx;
    
    totalBounds = NSMakeRect(baseOrigin.x,baseOrigin.y,0.0f,0.0f);
       
    // Get bounds of whole region.
    count = [cardsToDrag count];
    for (i = 0; i < count; i++) {
        totalBounds = NSUnionRect(totalBounds,[[cardsToDrag objectAtIndex:i] bounds]);
    }
    
    // Create image large enough for dragged cards.
    image = [[NSImage alloc] initWithSize:totalBounds.size];
    
    [image lockFocus];
    ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    
    // We do this offset so the cards can render in their normal coordinate system.
    CGContextTranslateCTM(ctx, -totalBounds.origin.x,-totalBounds.origin.y);
    
    for (i = 0; i < count; i++) {
        card = [cardsToDrag objectAtIndex:i];
        [card draw];
    }
    CGContextRestoreGState(ctx);
    [image unlockFocus];
    
    *dragOffset = NSMakePoint(totalBounds.origin.x,totalBounds.origin.y);

    return image;
}

// Subclasses must override this based on game specific rules.
- (NSArray *)cardsForDragFromCard:(Card *)card index:(unsigned)dragIndex
{
    return nil;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)theRect
{    
    // We always redo layout since our bounds may have changed.
    [self layoutCards];
    [_cards makeObjectsPerformSelector:@selector(draw)];    
}

// =========== Drag / Undo ========
// below code works on 10.5(ppc), but doesn't work (undo move) on 10.6(intel)
//

// Drag source operations.
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	if (flag) {
		return NSDragOperationPrivate;
	} else {
		return NSDragOperationNone;
	}
}

// Drag source operation
- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint
{
//	NSLog(@"Drag began");
    [_cards removeObjectsInArray:[control cardsBeingDragged]];	// remove cards without undo reg
    [self setNeedsDisplay:YES];
}

// Drag source operation
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    // If the drag failed then take the cards back.
    NSArray *draggedCards = [control cardsBeingDragged];
    
    if (operation == NSDragOperationNone) {	// Drag failed, take cards back
//		NSLog(@"Drag ended (None)");
        [_cards addObjectsFromArray:draggedCards];	// return cards without undo reg
        [self setNeedsDisplay:YES];
    } else {							// Drag succeeded
//		NSLog(@"Drag ended (source)");
        [[[control undoManager] prepareWithInvocationTarget:self] addCardsFromArray:draggedCards];
//        [[control undoManager] registerUndoWithTarget:self
//								selector:@selector(addCardsFromArray:)
//								object:draggedCards];
    }
}

// Drag destination operations.
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
//	NSLog(@"Drag entered");
    return NSDragOperationPrivate;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
//	NSLog(@"Drag operation (dest)");
    [self addCardsFromArray:[control cardsBeingDragged]];
    return YES;
}

// Primitives (with undo registration)
- (void)removeCardsInArray:(NSArray *)cards	// ##undo
{
//	NSLog(@"removeCards (with undo reg)");
    [[[control undoManager] prepareWithInvocationTarget:self] addCardsFromArray:cards];
//	[[control undoManager] registerUndoWithTarget:self
//							selector:@selector(addCardsFromArray:)
//							object:cards];
    [_cards removeObjectsInArray:cards];
    [self setNeedsDisplay:YES];
}

- (void)addCardsFromArray:(NSArray *)cards	// ##undo
{
//	NSLog(@"addCards (with undo reg)");
    [[[control undoManager] prepareWithInvocationTarget:self] removeCardsInArray:cards];
//	[[control undoManager] registerUndoWithTarget:self
//							selector:@selector(removeCardsInArray:)
//							object:cards];
    [_cards addObjectsFromArray:cards];
    [self setNeedsDisplay:YES];
}

@end
