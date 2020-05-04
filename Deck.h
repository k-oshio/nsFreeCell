//
//  Deck.h
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Card;

@interface Deck : NSObject {
    NSMutableArray *cards;
}

- (id)initWithStandardDeck;
- (void)shuffleWithSeed:(unsigned)seed;
- (unsigned)count;
- (Card *)cardAtIndex:(unsigned)index;

@end
