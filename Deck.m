//
//  Deck.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//

#import "Deck.h"
#import "Card.h"

#define min(a,b) ((a) < (b) ? (a) : (b))

@implementation Deck

- (id)initWithStandardDeck
{
    Card        *card;
    SuitType    suit;
    RankType    rank;
    
    self = [super init];
    cards = [NSMutableArray arrayWithCapacity:52];
    for (rank = kKing; rank >= kAce; rank--) {
        for (suit = kHearts; suit < kNumSuits; suit++) {
            // By default cards are face down.
            card = [[Card alloc] initWithSuit:suit rank:rank facingUp:NO];
            [cards addObject:card];
        }
    }
    return self;
}


- (void)shuffleWithSeed:(unsigned)seed
{
    int             i, count, iterations;
    int             mode = 0;   // 0 doesn't work yet... 1 is ok
    NSMutableArray  *shuffleArray1, *shuffleArray2;

    srandom(seed);
    
    // Iterate over deck a bunch of times, swapping two random cards.
    count = [cards count];
    
    // This seems to be sufficient.
    iterations = 52;

    shuffleArray1 = [NSMutableArray arrayWithCapacity:count];
    shuffleArray2 = [NSMutableArray arrayWithCapacity:count];
    [shuffleArray1 addObjectsFromArray:cards];  // 1 is regular deck, 2 is empty

    if (mode == 0) {
        // Yet another attempt at a decent shuffling routine.  I'm still not happy
        // with the randomness yet.
        for (i = 0; i < iterations; i++) {
            unsigned long   cutIndex;
            unsigned long   d1, d2, dest;
            long            pull;
            NSMutableArray  *temp;
            
            // Pick a random cut point near the middle of the deck, +/- 10 cards or so.
            cutIndex = (random() % 10) - 5 + count/2;
            
            d1 = 0;
            d2 = cutIndex;
            dest = 0;
            
            // Randomly swap the two halves.
            
            // Now "shuffle" the cards into a new deck.  We alternate taking 1-3 cards
            // from each half.
            [shuffleArray2 removeAllObjects];
            while ((d1 < cutIndex) || (d2 < count)) {
                // Pull cards from "deck" 1.
                pull = (random() % 2) + 1;
                // Don't take more cards than we have left.  We may have 0 left, so that's
                // okay.
                
                // Randomly swap the two halves.
                if (d1 == 0 && ((random() % 65536) < 32768)) pull = 0;
                
                pull = min(cutIndex - d1,pull);
                while (pull-- > 0) {
                    [shuffleArray2 insertObject:[shuffleArray1 objectAtIndex:d1++] atIndex:dest++];
                }
                // Pull cards from "deck" 2.
                pull = (random() % 2) + 1;
                // Don't take more cards than we have left.  We may have 0 left, so that's
                // okay.
                pull = min(count - d2, pull);
                while(pull-- > 0) {
                //    shuffleArray2[dest++] = shuffleArray1[d2++];
                    [shuffleArray2 insertObject:[shuffleArray1 objectAtIndex:d2++] atIndex:dest++];
                }
            }
            // Now exchange arrays for next round.
            assert(d1 = cutIndex);
            assert(d2 = count);
            assert(dest == count);
            temp = shuffleArray1;
            shuffleArray1 = shuffleArray2;
            shuffleArray2 = temp;
        }
        
        } else {
        // Simple shuffling algorithm.  Just randomly pulls cards from
        // the deck into another array.  Then randomly pulls them all back.
        for (i = 0; i < iterations; i++) {
            unsigned    cardIndex;
            int         remaining;
            Card        *c;

            [shuffleArray2 removeAllObjects];
            for (remaining = count; remaining > 0; remaining--) {
                cardIndex = random() % remaining;
                c = [shuffleArray1 objectAtIndex:cardIndex];
                [shuffleArray1 removeObjectAtIndex:cardIndex];
                [shuffleArray2 insertObject:c atIndex:count - remaining];
            }
            
            [shuffleArray1 removeAllObjects];
            for (remaining = count; remaining > 0; remaining--) {
                cardIndex = random() % remaining;
                 c = [shuffleArray2 objectAtIndex:cardIndex];
                [shuffleArray2 removeObjectAtIndex:cardIndex];
                [shuffleArray1 insertObject:c atIndex:count - remaining];
            }
        }
    }
    cards = [NSMutableArray arrayWithArray:shuffleArray1];
}

- (unsigned)count
{
    return [cards count];
}

- (Card *)cardAtIndex:(unsigned)index
{
    return [cards objectAtIndex:index];
}

@end
