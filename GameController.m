//
//  GameController.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

//	### undo still not working correctly

#import "GameController.h"
#import "Card.h"
#import "Deck.h"
#import "CardView.h"
#import "FreeCellView.h"
#import "HomeView.h"
#import "StackView.h"
#include <sys/time.h>

#define AUTO_WAIT	0.01f

@implementation GameController

- (id)init
{
    self = [super init];
	didWin = NO;

    undoManager = [[NSUndoManager alloc] init];
    
    return self;
}

- (void)awakeFromNib
{
    freeCellViews[0] = cell1;
    freeCellViews[1] = cell2;
    freeCellViews[2] = cell3;
    freeCellViews[3] = cell4;
    homeCellViews[0] = home1;
    homeCellViews[1] = home2;
    homeCellViews[2] = home3;
    homeCellViews[3] = home4;
    stackViews[0] = stack1;
    stackViews[1] = stack2;
    stackViews[2] = stack3;
    stackViews[3] = stack4;
    stackViews[4] = stack5;
    stackViews[5] = stack6;
    stackViews[6] = stack7;
    stackViews[7] = stack8;

    [seedField setIntegerValue:seed];
}

- (NSUndoManager *)undoManager
{
    return undoManager;
}

// Window delegate method that seems to be required in order for
// Undo to function properly.  Without it, automatic menu validation
// seems to not work, even if we respond to undo: ourselves.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return undoManager;
}

// Reset the game board and fill it with a new deck of cards.
- (void)initGameCards
{
    int i;
    Card *card;
    Deck *deck;

	[Card setControl:self];

    for (i = 0; i < 8; i++) {
        [stackViews[i] removeAllCards];
        [stackViews[i] display];
    }
    
    for (i = 0; i < 4; i++) {
        [homeCellViews[i] removeAllCards];
        [freeCellViews[i] removeAllCards];
        [homeCellViews[i] display];
        [freeCellViews[i] display];
    }
    
    deck = [[Deck alloc] initWithStandardDeck];
    [deck shuffleWithSeed:seed];

    // "Deal cards" into stacks.
    for (i = 0; i < [deck count]; i++) {
        card = [deck cardAtIndex:i];
        [stackViews[i % 8] addCard:card facingUp:YES];
        [NSThread sleepForTimeInterval:AUTO_WAIT];
        [stackViews[i % 8] display];
    //    [stackViews[i % 8] setNeedsDisplay:YES];	// this doesn't work
    }
}

// Keep track of which cards are being dragged.  We do this
// here for simplicity, rather than writing a bunch of code that
// could archive/dearchive the cards onto the pasteboard during
// the drag operation.
- (void)setCardsBeingDragged:(NSArray *)cards source:(id)source
{
    cardsBeingDragged = cards;
	dragSource = source;
}

- (NSArray *)cardsBeingDragged
{
    return cardsBeingDragged;
}

- (id)dragSource
{
	return dragSource;
}

- (unsigned)freeCellsNotIncludingView:(CardView *)view
{
    unsigned i, freeCells = 0;
    
    for (i = 0; i < 4; i++) {
        if((CardView *)freeCellViews[i] != view && [freeCellViews[i] count] == 0) {
            freeCells++;
		}
    }

    for (i = 0; i < 8; i++) {
        if ((CardView *)stackViews[i] != view && [stackViews[i] count] == 0) {
            freeCells++;
		}
    }
    
    return freeCells;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [Card generateGlyphInfo];
    [self loadDefaults];
    [self restartGame:nil];
}

// This method does any move post processing, such as doing automatic
// assists and checking for end game conditions.
- (void)updateGame
{
    unsigned	i, j;
    Card		*card;
    RankType	rank;
    SuitType	suit;
    BOOL		found;
    Card		*exposedCards[kNumSuits];
    
    // Look for any obvious automatic moves we can do to assist the user.
    
    // First, look for any exposed aces.
    do {
        found = NO;
        for (i = 0; i < 8; i++) {
            card = [stackViews[i] topCard];
            if ([card rank] == kAce) {
                found = YES;
                for (j = 0; j < 4; j++) {
                    if (![homeCellViews[j] count]) {
                        [homeCellViews[j] addCard:card facingUp:YES]; // #undo
                        [NSThread sleepForTimeInterval:AUTO_WAIT];
                        [homeCellViews[j] display];
                        break;
                    }
                }
                [stackViews[i] removeTopCard]; // #undo
                [stackViews[i] display];
            }
        }
    } while(found);
    
    // Now try to auto-place other exposed cards.
    for (rank = kAce; rank <= kKing; rank++) {
        exposedCards[kHearts] = 0;
        exposedCards[kClubs] = 0;
        exposedCards[kDiamonds] = 0;
        exposedCards[kSpades] = 0;
        
        for (suit = kHearts; suit <= kClubs; suit++) {
            for (i = 0; i < 8; i++) {
                card = [stackViews[i] topCard];
                if ([card rank] == rank && [card suit] == suit) {
                    exposedCards[suit] = card;
                }
            }
            for (i = 0; i < 4; i++) {
                card = [freeCellViews[i] topCard];
                if ([card rank] == rank && [card suit] == suit) {
                    exposedCards[suit] = card;
                }
            }
            
            // This is done to just simplify the test...
            // If the card is already in the home row anywhere
            // then it counts as exposed.

            for (i = 0; i < 4; i++) {
               if ([homeCellViews[i] containsCardWithSuit:suit rank:rank])
                    exposedCards[suit] = [homeCellViews[i] topCard];
            }
        }
        
        // If all of the suits of this rank are exposed,
        // then we don't need them any more and will auto-
        // place them into their home rows.
        if(exposedCards[kHearts] && exposedCards[kClubs] &&
           exposedCards[kDiamonds] && exposedCards[kSpades]) {
            
            // Do it for the stack views...
            for (i = 0; i < 8; i++) {
                card = [stackViews[i] topCard];
                if ([card rank] == rank) {
                    for (j = 0; j < 4; j++) {
                        if ([[homeCellViews[j] topCard] suit] == [card suit]) {
                            // Matching home cell.  Put card here.
                            [homeCellViews[j] addCard:card facingUp:YES]; // #undo
                            [stackViews[i] removeTopCard]; // #undo
                            [NSThread sleepForTimeInterval:AUTO_WAIT];
                            [homeCellViews[j] display];
                            [stackViews[i] display];
                            break;
                        }
                    }
                }
            }
            // Again for the free cells...
            for (i = 0; i < 4; i++) {
                card = [freeCellViews[i] topCard];
                if ([card rank] == rank) {
                    for (j = 0; j < 4; j++) {
                        if ([[homeCellViews[j] topCard] suit] == [card suit]) {
                            // Matching home cell.  Put card here.
                            [homeCellViews[j] addCard:card facingUp:YES]; // #undo
                            [freeCellViews[i] removeTopCard]; // #undo
                            [NSThread sleepForTimeInterval:AUTO_WAIT];
                            [homeCellViews[j] display];
                            [freeCellViews[i] display];
                            break;
                        }
                    }
                }
            }
        } else {
            // No matches found, so by definition we can't match any
            // higher ranks.
            break;
        }
    }
    
    // Check for won game.  Just look for full home rows.
    if ([homeCellViews[0] count] == 13 && [homeCellViews[1] count] == 13 &&
       [homeCellViews[2] count] == 13 && [homeCellViews[3] count] == 13) {
        // Inform user that she won.
        NSBeginInformationalAlertSheet(
			@"You won!", @"New game", @"Replay", @"Cancel",
			window, self,
            @selector(sheetDidEnd:returnCode:contextInfo:), 
            @selector(sheetDidDismiss:returnCode:contextInfo:),nil,@"");
            
        // If we haven't won this game, then claim that we have and update statistics.
        // That way if the user replays the same game, whether or not she wins or loses
        // won't change our running statistics.
        if (!didWin) {
            didWin = YES;
            totalWon++;
            winningStreak++;
            losingStreak = 0;
            [self updateStatistics];
            [self saveDefaults];
        }
    }
    
    // TODO: Look for a game that is definitely unwinnable.
}

// This is apparently required, although we don't do anything with it.
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    return;
}

// Once the sheet is gone we decide what to do next.
- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertOtherReturn) {
        return;
	}

    if (returnCode == NSAlertDefaultReturn) {
        [self newGame:nil];
        return;
    }
    [self restartGame:nil];
}

- (void)newGame:(id)sender
{
    // If a new game is being started and the current one being played
    // hasn't been won then log the current game as a loss.
    if (!didWin) {
        totalLost++;
        losingStreak++;
        winningStreak = 0;
        [self updateStatistics];
    }
    didWin = NO;
    [self generateRandomSeed];
    [self saveDefaults];
    [self restartGame:nil];
}

- (void)restartGame:(id)sender	// ##undo
{
    @autoreleasepool {
        [self initGameCards];
        [undoManager removeAllActions];
        [window displayIfNeeded];
        [self updateGame];
    }
}

- (void)generateRandomSeed
{
    // Generate new random seed value.
    struct timeval tv;
    gettimeofday(&tv,NULL);
    seed = tv.tv_sec ^ (tv.tv_usec << 16);
    [seedField setIntegerValue:seed];
}

// Code to deal with statistics window.
- (void)showStatistics:(id)sender
{
    if(!statsWindow) {
        [NSBundle loadNibNamed:@"StatsWindow.nib" owner:self];
	}
    [self updateStatistics];
    [statsWindow makeKeyAndOrderFront:self];
}

- (void)resetStatistics:(id)sender
{
    totalWon = 0;
    totalLost = 0;
    winningStreak = 0;
    losingStreak = 0;
    [self updateStatistics];
    [self saveDefaults];
}

- (void)updateStatistics
{
    [wonField setIntValue:totalWon];
    [loseField setIntValue:totalLost];
    [winStreakField setIntValue:winningStreak];
    [loseStreakField setIntValue:losingStreak];
}


// Code to load and save preferences (current game seed) and stats.
- (void)loadDefaults
{
    NSNumber *number;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    number = [defaults objectForKey:@"Seed"];
    if (number) {
        seed = [number unsignedIntValue];
	} else {
        [self generateRandomSeed];
	}
    
    number = [defaults objectForKey:@"Wins"];
    totalWon = number ? [number unsignedIntValue] : 0;
    number = [defaults objectForKey:@"Losses"];
    totalLost = number ? [number unsignedIntValue] : 0;
    number = [defaults objectForKey:@"WinningStreak"];
    winningStreak = number ? [number unsignedIntValue] : 0;
    number = [defaults objectForKey:@"LosingStreak"];
    losingStreak = number ? [number unsignedIntValue] : 0;

    [self saveDefaults];
}

- (void)saveDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithUnsignedInt:seed] forKey:@"Seed"];
    [defaults setObject:[NSNumber numberWithUnsignedInt:totalWon] forKey:@"Wins"];
    [defaults setObject:[NSNumber numberWithUnsignedInt:totalLost] forKey:@"Losses"];
    [defaults setObject:[NSNumber numberWithUnsignedInt:winningStreak] forKey:@"WinningStreak"];
    [defaults setObject:[NSNumber numberWithUnsignedInt:losingStreak] forKey:@"LosingStreak"];
    [defaults synchronize];
}

// Internal method used to generate the app icon.
- (void)generateIcon:(id)sender
{
    NSImage		*iconImage = [Card iconImage];
    NSData		*tiffData;

    tiffData = [iconImage TIFFRepresentation];
    [tiffData writeToFile:@"/tmp/FreeCell.tiff" atomically:NO];
}

// ko (quick fix for 10.4)
/*
- (void)windowDidResize:(NSNotification *)notification
{
    int i;
    for (i = 0; i < 4; i++) {
        [freeCellViews[i] display];
    }
    for (i = 0; i < 4; i++) {
        [homeCellViews[i] display];
    }
}
*/

@end
