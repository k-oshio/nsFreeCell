//
//  BackgroundView.m
//  nsFreeCell
//
//  Created by kdyke on Sat Apr 14 2001.
//  Copyright (c) 2001 nsObject.com. All rights reserved.
//
#import "BackgroundView.h"

@implementation BackgroundView

// I could never make the background color for NSWindow work right, so I
// simply stick this view into the window.  What I probably should do is 
// just make this view the content view of the window and remove the one
// in Interface Builder.  Fixme.

// ko
// This view now contains StackView, FreeCellView etc.
//
- (BOOL)isOpaque
{
    return YES;
}

- (id)initWithFrame:(NSRect)theFrame
{
    self = [super initWithFrame:theFrame];
    
    // Cache the background color.
    color = [NSColor colorWithCalibratedRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [color set];
    NSRectFill(rect);
}

@end
