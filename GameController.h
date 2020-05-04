//
//  GameController.h
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

//	### undo still not working correctly

#import <Cocoa/Cocoa.h>

@class FreeCellView;
@class HomeView;
@class StackView;
@class CardView;

@interface GameController : NSObject
{
    IBOutlet FreeCellView	*cell1;
    IBOutlet FreeCellView	*cell2;
    IBOutlet FreeCellView	*cell3;
    IBOutlet FreeCellView	*cell4;
    IBOutlet HomeView		*home1;
    IBOutlet HomeView		*home2;
    IBOutlet HomeView		*home3;
    IBOutlet HomeView		*home4;
    IBOutlet StackView		*stack1;
    IBOutlet StackView		*stack2;
    IBOutlet StackView		*stack3;
    IBOutlet StackView		*stack4;
    IBOutlet StackView		*stack5;
    IBOutlet StackView		*stack6;
    IBOutlet StackView		*stack7;
    IBOutlet StackView		*stack8;
    IBOutlet NSWindow		*window;
    
    NSArray *cardsBeingDragged;
	id		dragSource;

//    FreeCellView	**freeCellViews;
//    HomeView		**homeCellViews;
//    StackView		**stackViews;
    FreeCellView	*freeCellViews[4];
    HomeView		*homeCellViews[4];
    StackView		*stackViews[8];
    unsigned		seed;
    IBOutlet id		seedField;

    NSUndoManager	*undoManager;
    BOOL			didWin;
    
    IBOutlet id		statsWindow;
    IBOutlet id		wonField;
    IBOutlet id		loseField;
    IBOutlet id		winStreakField;
    IBOutlet id		loseStreakField;
    
    unsigned		totalWon;
    unsigned		totalLost;
    unsigned		winningStreak;
    unsigned		losingStreak;
    
}

- (void)setCardsBeingDragged:(NSArray *)cards source:(id)source;
- (NSArray *)cardsBeingDragged;
- (id)dragSource;
- (void)updateGame;
- (void)generateRandomSeed;
- (unsigned)freeCellsNotIncludingView:(CardView *)view;
- (void)newGame:(id)sender;
- (void)restartGame:(id)sender;
- (void)generateIcon:(id)sender;
- (NSUndoManager *)undoManager;
- (void)loadDefaults;
- (void)saveDefaults;

- (void)updateStatistics;
- (void)showStatistics:(id)sender;
- (void)resetStatistics:(id)sender;

@end
