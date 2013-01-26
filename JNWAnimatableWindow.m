/*
 Copyright (c) 2013, Jonathan Willing. All rights reserved.
 Licensed under the MIT license <http://opensource.org/licenses/MIT>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 IN THE SOFTWARE.
 */


#import "JNWAnimatableWindow.h"
#import <QuartzCore/QuartzCore.h>

static NSUInteger JNWAnimatableWindowOpenTransactions = 0;

static const CGFloat JNWAnimatableWindowShadowOpacity = 0.8f;
static const CGSize JNWAnimatableWindowShadowOffset = (CGSize){ 0, -18 };
static const CGFloat JNWAnimatableWindowShadowRadius = 22.f;
#define JNWAnimatableWindowShadowColor [NSColor blackColor]

@interface JNWAnimatableWindowContentView : NSView
@end

@interface JNWAnimatableWindow() {
	// When we want to move the window off-screen to take the screen shot, we want
	// to make sure we aren't being constranied.
	BOOL _disableConstrainedWindow;
}

@property (nonatomic, strong) NSWindow *fullScreenWindow;
@property (nonatomic, strong) CALayer *windowRepresentationLayer;
@end

@implementation JNWAnimatableWindow



#pragma mark Initialization

- (void)initializeWindowRepresentationLayer {
	self.windowRepresentationLayer = [CALayer layer];
	self.windowRepresentationLayer.contentsScale = self.backingScaleFactor;
	
	// Set some reasonable default shadows which are not guaranteed to be the same as OS.
	self.windowRepresentationLayer.shadowColor = JNWAnimatableWindowShadowColor.CGColor;
	self.windowRepresentationLayer.shadowOffset = JNWAnimatableWindowShadowOffset;
	self.windowRepresentationLayer.shadowRadius = JNWAnimatableWindowShadowRadius;
	self.windowRepresentationLayer.shadowOpacity = JNWAnimatableWindowShadowOpacity;
	
	self.windowRepresentationLayer.shouldRasterize = YES;
	self.windowRepresentationLayer.rasterizationScale = self.backingScaleFactor;
}

- (void)initializeFullScreenWindow {
	self.fullScreenWindow = [[NSWindow alloc] initWithContentRect:self.screen.frame
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO screen:self.screen];
	self.fullScreenWindow.animationBehavior = NSWindowAnimationBehaviorNone;
	self.fullScreenWindow.backgroundColor = [NSColor clearColor];
	self.fullScreenWindow.movableByWindowBackground = NO;
	self.fullScreenWindow.ignoresMouseEvents = YES;
	self.fullScreenWindow.level = self.level;
	self.fullScreenWindow.hasShadow = NO;
	self.fullScreenWindow.opaque = NO;
	self.fullScreenWindow.contentView = [[JNWAnimatableWindowContentView alloc] initWithFrame:[self.fullScreenWindow.contentView bounds]];
}



#pragma mark Getters

- (CALayer *)layer {
	[self setupIfNeeded];
	return self.windowRepresentationLayer;
}



#pragma mark Setup and Drawing

- (void)setupIfNeeded {
	[self setupIfNeededWithSetupBlock:nil];
}

- (void)setupIfNeededWithSetupBlock:(void(^)(CALayer *))setupBlock {
	if (self.windowRepresentationLayer != nil) {
		if (self.windowRepresentationLayer.animationKeys.count) {
			[self.windowRepresentationLayer removeAllAnimations];
		}
		return;
	}
	
	BOOL onScreen = [self isVisible];
	
	[self initializeFullScreenWindow];
	[self initializeWindowRepresentationLayer];
	
	[[self.fullScreenWindow.contentView layer] addSublayer:self.windowRepresentationLayer];
	self.windowRepresentationLayer.frame = self.frame;

	
	CGRect originalWindowFrame = self.frame;
	
	if (!onScreen) {
		// So the window is closed, and we need to get a screenshot of it without flashing.
		// First, we find the frame that covers all the connected screens.
		CGRect allWindowsFrame = CGRectZero;
		
		for(NSScreen *screen in [NSScreen screens]) {
            allWindowsFrame = NSUnionRect(allWindowsFrame, screen.frame);
		}
		
		// Position our window to the very right-most corner out of visible range, plus padding for the shadow.
		CGRect frame = (CGRect){
			.origin = CGPointMake(CGRectGetWidth(allWindowsFrame) + 2*JNWAnimatableWindowShadowRadius, 0),
			.size = originalWindowFrame.size
		};
		_disableConstrainedWindow = YES;
		
		self.alphaValue = 0.f;		
		[self setFrame:frame display:NO];
		[super makeKeyAndOrderFront:nil];
		
		_disableConstrainedWindow = NO;
	}
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	self.alphaValue = 1.f;
	[self updateImageRepresentation];
	
	if (setupBlock != nil)
		setupBlock(self.windowRepresentationLayer);
	[CATransaction commit];
	
	[self.fullScreenWindow makeKeyAndOrderFront:nil];
	self.alphaValue = 0.f;
	
	// If we moved the window offscreen to get the screenshot, we want to move back to the original frame
	if (!CGRectEqualToRect(originalWindowFrame, self.frame)) {
		[self setFrame:originalWindowFrame display:NO];
	}		
}

- (void)updateImageRepresentation {
	CGImageRef capture = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, (CGWindowID)self.windowNumber, kCGWindowImageBoundsIgnoreFraming);
	NSImage *image = [[NSImage alloc] initWithCGImage:capture size:CGSizeMake(CGImageGetWidth(capture), CGImageGetHeight(capture))];
	self.windowRepresentationLayer.contents = image;//(__bridge id)image;
	CGImageRelease(capture);
}



#pragma mark Window Overrides

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
	return (_disableConstrainedWindow ? frameRect : [super constrainFrameRect:frameRect toScreen:screen]);
}



#pragma mark Convenince Window Methods

- (void)orderOutWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction animations:(void (^)(CALayer *))animations {
	[self setupIfNeeded];
	[super orderOut:nil];
	[self performAnimations:animations withDuration:duration timingFunction:timingFunction];
}

- (void)makeKeyAndOrderFrontWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction
								   setup:(void (^)(CALayer *))setup animations:(void (^)(CALayer *))animations {
	[self setupIfNeededWithSetupBlock:setup];
	if (!self.isVisible)
		[super makeKeyAndOrderFront:nil];
	[self performAnimations:animations withDuration:duration timingFunction:timingFunction];
}

- (void)performAnimations:(void (^)(CALayer *layer))animations withDuration:(CFTimeInterval)duration timingFunction:(CAMediaTimingFunction *)timingFunction {
	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setAnimationTimingFunction:(timingFunction ?: [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut])];
	[CATransaction setCompletionBlock:^{
		JNWAnimatableWindowOpenTransactions--;
		if (JNWAnimatableWindowOpenTransactions == 0) {
			[self destroyTransformingWindow];
		}
	}];
	
	animations(self.windowRepresentationLayer);
	JNWAnimatableWindowOpenTransactions++;
	
	[CATransaction commit];
}



#pragma mark Lifecycle

- (void)destroyTransformingWindow {	
	self.alphaValue = 1.f;
	
	[self.windowRepresentationLayer removeFromSuperlayer];
	self.windowRepresentationLayer = nil;
	
	[self.fullScreenWindow orderOut:nil];
	self.fullScreenWindow = nil;
}

@end

@implementation JNWAnimatableWindowContentView

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	
	self.layer = [CALayer layer];
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
	
	return self;
}

@end
