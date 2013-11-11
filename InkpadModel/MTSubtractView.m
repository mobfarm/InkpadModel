//
//  MTSubtractView.m
//  SubtractCircles
//
//  Created by Matteo Gavagnin on 07/11/13.
//  Copyright (c) 2013 MacTeo. All rights reserved.
//

#import "MTSubtractView.h"
#import "WDPath.h"
#import "WDPathfinder.h"

@implementation MTSubtractView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGRect bigCircle = CGRectMake(10, 10, 200, 200);
    CGRect smallCircle = CGRectInset(bigCircle, 50, 50);
    
    WDPath *circle = [WDPath pathWithOvalInRect:bigCircle];
    WDPath *circle2 = [WDPath pathWithOvalInRect:smallCircle];
    WDPath *circle3 = [WDPath pathWithOvalInRect:CGRectMake(80, 80, 300, 300)];
    WDPath *circle4 = [WDPath pathWithOvalInRect:CGRectMake(300, 100, 100, 100)];
    
    WDAbstractPath *unite = [WDPathfinder combinePaths:@[circle3, circle4] operation:WDPathfinderUnite];
    WDAbstractPath *subtract = [WDPathfinder combinePaths:@[circle, circle2] operation:WDPathFinderSubtract];
    WDAbstractPath *intersection = [WDPathfinder combinePaths:@[unite, subtract] operation:WDPathfinderIntersect];

//    //// Oval Drawing
//    UIBezierPath* circlePath = [UIBezierPath bezierPathWithCGPath:circle.pathRef];
//    [[UIColor blueColor] setFill];
//    [circlePath fill];
    
//    //// Oval 2 Drawing
//    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithCGPath:circle2.pathRef];
//    [[UIColor greenColor] setFill];
//    [oval2Path fill];
    
    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithCGPath:subtract.pathRef];
    [[UIColor yellowColor] setFill];
    [ovalPath fill];
    
    //// Oval 3 Drawing
    UIBezierPath* oval3Path = [UIBezierPath bezierPathWithCGPath:circle3.pathRef];
    [[UIColor redColor] setFill];
    [oval3Path fill];

    //// Oval 4 Drawing
    UIBezierPath* oval4Path = [UIBezierPath bezierPathWithCGPath:circle4.pathRef];
    [[UIColor purpleColor] setFill];
    [oval4Path fill];

    //// Oval 5 Drawing
    UIBezierPath* oval5Path = [UIBezierPath bezierPathWithCGPath:unite.pathRef];
    [[UIColor grayColor] setFill];
    [oval5Path fill];
    
    //// Oval 5 Drawing
    UIBezierPath* oval6Path = [UIBezierPath bezierPathWithCGPath:intersection.pathRef];
    [[UIColor orangeColor] setFill];
    [oval6Path fill];
}


@end
