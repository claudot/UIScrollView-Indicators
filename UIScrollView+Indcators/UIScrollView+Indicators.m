//
// The MIT License (MIT)
//
// Copyright (c) 2014 Paul-Anatole CLAUDOT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "UIScrollView+Indicators.h"

// Image
const char * const pachorizontalScrollIndicatorStoreKey = "pac.scrollview.horizontalIndicator";
const char * const pacverticalScrollIndicatorStoreKey = "pac.scrollview.verticalIndicator";

// Layer
const char * const pachorizontalScrollIndicatorLayerStoreKey = "pac.scrollview.horizontalIndicatorLayer";
const char * const pacverticalScrollIndicatorLayerStoreKey = "pac.scrollview.verticalIndicatorLayer";

@implementation UIScrollView (indicators)

- (void)registerToContentOffsetChange
{
    @try {
        [self removeObserver:self forKeyPath:@"contentOffset" context:nil];
        [self removeObserver:self forKeyPath:@"contentSize" context:nil];
    }
    @catch (NSException *exception) {
        
    }
    [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"] || [keyPath isEqualToString:@"contentSize"]) {
        if (self.contentSize.width > 0.0f && self.contentSize.height > 0.0f) {
            [self updateContent];
        }
    }
}

- (void)updateContent
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [[self customHorizontalScrollIndicatorLayer] setOpacity:1.0];
    [[self customVerticalScrollIndicatorLayer] setOpacity:1.0];
    
    [[self customHorizontalScrollIndicatorLayer] setHidden:(self.contentSize.width <= self.frame.size.width)];
    [[self customVerticalScrollIndicatorLayer] setHidden:(self.contentSize.height <= self.frame.size.height)];
    
    CGFloat xOffset = ((self.contentOffset.x / (self.contentSize.width - self.frame.size.width)) * (self.frame.size.width - [self customHorizontalScrollIndicator].size.width)) + self.contentOffset.x;
    CGFloat yOffset = ((self.contentOffset.y / (self.contentSize.height - self.frame.size.height)) * (self.frame.size.height - [self customVerticalScrollIndicator].size.height)) + self.contentOffset.y;

    if (self.contentSize.width - self.frame.size.width > 0.0f) {
        CGRect frame = [self customHorizontalScrollIndicatorLayer].frame;
        frame.origin.x = xOffset;
        frame.origin.y = self.contentOffset.y + self.frame.size.height - frame.size.height;
        [[self customHorizontalScrollIndicatorLayer] setFrame:frame];
    
        [self compressHorizontal];
    }
    
    if (self.contentSize.height - self.frame.size.height > 0.0f) {
        CGRect frame = [self customVerticalScrollIndicatorLayer].frame;
        frame.origin.y = yOffset;
        frame.origin.x = self.contentOffset.x + self.frame.size.width - frame.size.width;
        [[self customVerticalScrollIndicatorLayer] setFrame:frame];
        
        [self compressVertical];
    }
    
    [CATransaction commit];
    
    __block __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        [[weakSelf customHorizontalScrollIndicatorLayer] setOpacity:0.0];
        [[weakSelf customVerticalScrollIndicatorLayer] setOpacity:0.0];
    });
}

- (void)compressVertical
{
    CGRect frame = [self customVerticalScrollIndicatorLayer].frame;
    if (self.contentOffset.y < 0.0f) {
        frame.origin.y = self.contentOffset.y;
        frame.size.height = (1.0f - (fabsf(self.contentOffset.y) / self.frame.size.height)) * [self customVerticalScrollIndicator].size.height;
    }
    else if (self.contentOffset.y > self.contentSize.height - self.frame.size.height) {
        frame.size.height = fabsf((1.0f - (fabsf((self.contentSize.height + self.frame.size.height) - self.contentOffset.y) / self.frame.size.height)) * [self customVerticalScrollIndicator].size.height);
        frame.origin.y = self.contentOffset.y + self.frame.size.height - frame.size.height;
    }
    else {
        frame.size.height = [self customVerticalScrollIndicator].size.height;
    }
    [[self customVerticalScrollIndicatorLayer] setFrame:frame];
}

- (void)compressHorizontal
{
    CGRect frame = [self customHorizontalScrollIndicatorLayer].frame;
    if (self.contentOffset.x < 0.0f) {
        frame.origin.x = self.contentOffset.x;
        frame.size.width = (1.0f - (fabsf(self.contentOffset.x) / self.frame.size.width)) * [self customHorizontalScrollIndicator].size.width;
    }
    else if (self.contentOffset.x > self.contentSize.width - self.frame.size.width) {
        frame.size.width = fabsf((1.0f - (fabsf((self.contentSize.width + self.frame.size.width) - self.contentOffset.x) / self.frame.size.width)) * [self customHorizontalScrollIndicator].size.width);
        frame.origin.x = self.contentOffset.x + self.frame.size.width - frame.size.width;
    }
    else {
        frame.size.width = [self customVerticalScrollIndicator].size.width;
    }
    [[self customHorizontalScrollIndicatorLayer] setFrame:frame];
}

- (void)updateIndicators
{
    if ([self customHorizontalScrollIndicatorLayer] == nil) {
        CALayer *layer = [[CALayer alloc] init];
        [self.layer addSublayer:layer];
        [layer setOpacity:0.0f];
        [self setCustomHorizontalScrollIndicatorLayer:layer];
    }
    [self customHorizontalScrollIndicatorLayer].contents = (id)[self customHorizontalScrollIndicator].CGImage;
    [[self customHorizontalScrollIndicatorLayer] setFrame:CGRectMake(0.0f, self.frame.size.height - [[self customHorizontalScrollIndicator] size].height, [[self customHorizontalScrollIndicator] size].width, [[self customHorizontalScrollIndicator] size].height)];


    if ([self customVerticalScrollIndicatorLayer] == nil) {
        CALayer *layer = [[CALayer alloc] init];
        [self.layer addSublayer:layer];
        [layer setOpacity:0.0f];
        [self setCustomVerticalScrollIndicatorLayer:layer];
    }
    [self customVerticalScrollIndicatorLayer].contents = (id)[self customVerticalScrollIndicator].CGImage;
    [[self customVerticalScrollIndicatorLayer] setFrame:CGRectMake(self.frame.size.width - [[self customVerticalScrollIndicator] size].width, 0.0f, [[self customVerticalScrollIndicator] size].width, [[self customVerticalScrollIndicator] size].height)];
    
}

#pragma mark - Getter & Setter

- (void)setCustomHorizontalScrollIndicator:(UIImage *)customScrollIndicator
{
    if (customScrollIndicator != [self customHorizontalScrollIndicator]) {
        [self setShowsHorizontalScrollIndicator:NO];
        objc_setAssociatedObject(self, pachorizontalScrollIndicatorStoreKey, customScrollIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self registerToContentOffsetChange];
        [self updateIndicators];
    }
}

- (void)setCustomVerticalScrollIndicator:(UIImage *)customScrollIndicator
{
    if (customScrollIndicator != [self customVerticalScrollIndicator]) {
        [self setShowsVerticalScrollIndicator:NO];
        objc_setAssociatedObject(self, pacverticalScrollIndicatorStoreKey, customScrollIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self registerToContentOffsetChange];
        [self updateIndicators];
    }
}

- (UIImage *)customHorizontalScrollIndicator
{
    return (UIImage *) objc_getAssociatedObject(self, pachorizontalScrollIndicatorStoreKey);
}

- (UIImage *)customVerticalScrollIndicator
{
    return (UIImage *) objc_getAssociatedObject(self, pacverticalScrollIndicatorStoreKey);
}

- (void)setCustomHorizontalScrollIndicatorLayer:(CALayer *)customScrollIndicatorLayer
{
    if (customScrollIndicatorLayer != [self customHorizontalScrollIndicatorLayer]) {
        objc_setAssociatedObject(self, pachorizontalScrollIndicatorLayerStoreKey, customScrollIndicatorLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setCustomVerticalScrollIndicatorLayer:(CALayer *)customScrollIndicatorLayer
{
    if (customScrollIndicatorLayer != [self customVerticalScrollIndicatorLayer]) {
        objc_setAssociatedObject(self, pacverticalScrollIndicatorLayerStoreKey, customScrollIndicatorLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (CALayer *)customHorizontalScrollIndicatorLayer
{
    return (CALayer *) objc_getAssociatedObject(self, pachorizontalScrollIndicatorLayerStoreKey);
}

- (CALayer *)customVerticalScrollIndicatorLayer
{
    return (CALayer *) objc_getAssociatedObject(self, pacverticalScrollIndicatorLayerStoreKey);
}

@end
