//
//  WDAbstractPath.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#if !TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "WDAbstractPath.h"
#import "WDArrowhead.h"
#import "WDColor.h"
#import "WDCompoundPath.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDPathfinder.h"
#import "WDUtilities.h"

NSString *WDFillRuleKey = @"WDFillRuleKey";

@implementation WDAbstractPath

@synthesize fillRule = fillRule_;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeInteger:fillRule_ forKey:WDFillRuleKey];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    fillRule_ = (int) [coder decodeIntegerForKey:WDFillRuleKey];
    
    return self; 
}

- (CGPathRef) pathRef
{
    // implemented by subclasses
    return NULL;
}

- (CGPathRef) strokePathRef
{
    // implemented by subclasses
    return NULL;
}

- (BOOL) containsPoint:(CGPoint)pt
{
    return CGPathContainsPoint(self.pathRef, NULL, pt, false);
}

- (void) renderStrokeInContext:(CGContextRef)ctx
{
    CGContextAddPath(ctx, self.strokePathRef);
    [self.strokeStyle applyInContext:ctx];
    CGContextStrokePath(ctx);
}

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
    if (metaData.flags & WDRenderOutlineOnly) {
        CGContextAddPath(ctx, self.pathRef);
        CGContextStrokePath(ctx);
    } else if ([self.strokeStyle willRender] || self.fill || self.maskedElements) {
        [self beginTransparencyLayer:ctx metaData:metaData];
        
        if (self.fill) {
            [self.fill paintPath:self inContext:ctx];
        }
        
        if (self.maskedElements) {
            CGContextSaveGState(ctx);
            // clip to the mask boundary
            CGContextAddPath(ctx, self.pathRef);
            CGContextClip(ctx);
            
            // draw all the elements inside the mask
            for (WDElement *element in self.maskedElements) {
                [element renderInContext:ctx metaData:metaData];
            }
            
            CGContextRestoreGState(ctx);
        }
        
        if (self.strokeStyle && [self.strokeStyle willRender]) {
            [self renderStrokeInContext:ctx];
        }
        
        [self endTransparencyLayer:ctx metaData:metaData];
    }
}

- (NSString *) nodeSVGRepresentation {
    return nil;
}

- (NSUInteger) subpathCount
{
    return 1;
}

+ (WDAbstractPath *) pathWithCGPathRef:(CGPathRef)pathRef
{
    NSMutableArray *subpaths = [NSMutableArray array];
    
    CGPathApply(pathRef, (__bridge void *)(subpaths), &WDPathApplyAccumulateElement);
    
    if (subpaths.count == 1) {
        // single path
        return [subpaths lastObject];
    } else {
        WDCompoundPath *cp = [[WDCompoundPath alloc] init];
        [cp setSubpathsQuiet:subpaths];
        return cp;
    }
}

- (void) addElementsToOutlinedStroke:(CGMutablePathRef)pathRef
{
    // subclasses can add more to the outline
}

- (WDAbstractPath *) outlineStroke
{
    if (!self.strokeStyle || ![self.strokeStyle willRender]) {
        return nil;
    }
    
    CGRect              mediaBox = self.styleBounds;
    CFMutableDataRef	data = CFDataCreateMutable(NULL, 0);
    CGDataConsumerRef	consumer = CGDataConsumerCreateWithCFData(data);
    CGContextRef        ctx = CGPDFContextCreate(consumer, &mediaBox, NULL);
    CGMutablePathRef    mutableOutline;
    
    CGDataConsumerRelease(consumer);
    CGPDFContextBeginPage(ctx, NULL);
    
    [self.strokeStyle applyInContext:ctx];
    CGContextAddPath(ctx, self.strokePathRef);
    CGContextReplacePathWithStrokedPath(ctx);
    CGPathRef outline = CGContextCopyPath(ctx);
    
    CGPDFContextEndPage(ctx);
    CGContextRelease(ctx);
    CFRelease(data);
    
    if (CGPathIsEmpty(outline)) {
        CGPathRelease(outline);
        return nil;
    } else {
        mutableOutline = CGPathCreateMutableCopy(outline);
        CGPathRelease(outline);
    }

    [self addElementsToOutlinedStroke:mutableOutline];
    WDAbstractPath *result = [WDAbstractPath pathWithCGPathRef:mutableOutline];
    [result simplify];
    CGPathRelease(mutableOutline);
    
    // remove self intersections
    if (result) {
        result = [WDPathfinder combinePaths:@[result, [WDPath pathWithRect:result.styleBounds]] operation:WDPathfinderIntersect];
    }
    
    return result;
}

- (void) simplify
{
    // implemented by concrete subclasses
}

- (void) flatten
{
    // implemented by concrete subclasses
}

- (WDAbstractPath *) pathByFlatteningPath
{
    // implemented by concrete subclasses
    return nil;
}

- (NSArray *) erase:(WDAbstractPath *)erasePath
{
    // implemented by concrete subclasses
    return nil;
}

- (BOOL) isErasable
{
    return YES;
}

- (BOOL) canOutlineStroke
{
    return (self.strokeStyle && [self.strokeStyle willRender]) ? YES : NO;
}

- (id) copyWithZone:(NSZone *)zone
{       
    WDAbstractPath *ap = [super copyWithZone:zone];
    
    ap->fillRule_ = fillRule_;
    
    return ap;
}

@end
