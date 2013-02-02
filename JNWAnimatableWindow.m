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

// Since we're using completion blocks to determine when to kill the extra window, we need
// a way to keep track of the outstanding number of transactions, so we keep increment and
// decrement this to determine whether or not the completion block needs to be called.
static NSUInteger JNWAnimatableWindowOpenTransactions = 0;

// These are attempts at determining the default shadow settings on a normal window. These
// aren't perfect, but since NSWindow actually uses CGS functions to set the window I am not
// entirely sure there's a way I can get the exact information about shadow settings.
static const CGFloat JNWAnimatableWindowShadowOpacity = 0.8f;
static const CGSize JNWAnimatableWindowShadowOffset = (CGSize){ 0, -18 };
static const CGFloat JNWAnimatableWindowShadowRadius = 22.f;
#define JNWAnimatableWindowShadowColor [NSColor blackColor]

@interface JNWAnimatableWindowContentView : NSView
@end

@interface JNWAnimatableWindow() {
	// When we want to move the window off-screen to take the screen shot, we want
	// to make sure we aren't being constranied. Although the documentation does not
	// state that it constrains windows when moved using -setFrame:display:, such is the case.
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
	
	self.windowRepresentationLayer.shadowColor = JNWAnimatableWindowShadowColor.CGColor;
	self.windowRepresentationLayer.shadowOffset = JNWAnimatableWindowShadowOffset;
	self.windowRepresentationLayer.shadowRadius = JNWAnimatableWindowShadowRadius;
	self.windowRepresentationLayer.shadowOpacity = JNWAnimatableWindowShadowOpacity;
	//self.windowRepresentationLayer.shadowPath = CGPathCreateMutable();
	
	self.windowRepresentationLayer.contentsGravity = kCAGravityResize;
	self.windowRepresentationLayer.opaque = YES;
	
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
	// If the layer does not exist at this point, we create it and set it up.
	[self setupIfNeeded];
	
	return self.windowRepresentationLayer;
}



#pragma mark Setup and Drawing

- (void)setupIfNeeded {
	[self setupIfNeededWithSetupBlock:nil];
}

- (void)setupIfNeededWithSetupBlock:(void(^)(CALayer *))setupBlock {
	if (self.windowRepresentationLayer != nil) {
		return;
	}
		
	[self initializeFullScreenWindow];
	[self initializeWindowRepresentationLayer];
	
	[[self.fullScreenWindow.contentView layer] addSublayer:self.windowRepresentationLayer];
	self.windowRepresentationLayer.frame = self.frame;

	NSImage *image = [self imageRepresentationOffscreen:NO];
	
	// Begin a non-animated transaction to ensure that the layer's contents are set before we get rid of the real window.
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	self.windowRepresentationLayer.contents = image;
	
	// The setup block is called when we are ordering in. We want this non-animated and done before the the fake window
	// is shown, so we do in in the same transaction.
	if (setupBlock != nil)
		setupBlock(self.windowRepresentationLayer);
	
	[CATransaction commit];
	
	[self.fullScreenWindow makeKeyAndOrderFront:nil];

	// Effectively hide the original window. If we are ordering in, the window will become visible again once
	// the fake window is destroyed.
	self.alphaValue = 0.f;
}

- (NSImage *)imageRepresentationOffscreen:(BOOL)forceOffscreen {
	CGRect originalWindowFrame = self.frame;
	BOOL onScreen = self.isVisible;
	//CGFloat alpha = self.alphaValue;
	
	if (!onScreen || forceOffscreen) {
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
		
		// This is where things get nasty. Against what the documentation states, windows seem to be constrained
		// to the screen, so we override `constrainFrameRect:toScreen:` to return the original frame, which allows
		// us to put the window off-screen.
		_disableConstrainedWindow = YES;
		
		self.alphaValue = 0.f;
		if (!onScreen)
			[super makeKeyAndOrderFront:nil];
		
		[self setFrame:frame display:NO];
		
		_disableConstrainedWindow = NO;
	}
	
	// If we are ordering ourself in, we will be off-screen and will not be visible.
	self.alphaValue = 1.f;
	
	// Grab the image representation of the window, without the shadows.
	CGImageRef imageRef = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, (CGWindowID)self.windowNumber, kCGWindowImageBoundsIgnoreFraming);
	
	// So there's a problem. As it turns out, CGWindowListCreateImage() returns a CGImageRef
	// that apparently is backed by pixels that don't actually exist until they are queried.
	//
	// This is a significant problem, because what we actually want to do is to grab the image
	// from the window, then set its alpha to 0. But if the actual pixels haven't been grabbed
	// yet, then by the time we actually use them sometime later in the run loop the alpha of
	// the window will have already gone flying off into the distance and we're left with a
	// completely transparent image. That's no good.
	//
	// So here's a very nasty workaround. What we're doing is actually forcing the real pixels
	// to get copied over from the WindowServer by actually drawing them into another context
	// that has settings optimized for use with Core Animation. This isn't too wasteful, and it's
	// far better than actually copying over all of the real pixel data.
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
	CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0,
												 [[NSColorSpace deviceRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO]];
	NSImage *oldImage = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeZero];
	[oldImage drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];
	
	CGImageRef copiedImageRef = CGBitmapContextCreateImage(context);
	NSImage *image = [[NSImage alloc] initWithCGImage:copiedImageRef size:CGSizeZero];
	
	CGImageRelease(imageRef);
	CGImageRelease(copiedImageRef);
	CGContextRelease(context);
	
	// If we weren't originally on the screen, there's a good chance we shouldn't be visible yet.
	if (!onScreen || forceOffscreen)
		self.alphaValue = 0.f;
	
	// If we moved the window offscreen to get the screenshot, we want to move back to the original frame.
	if (!CGRectEqualToRect(originalWindowFrame, self.frame)) {
		[self setFrame:originalWindowFrame display:NO];
	}
	
	return image;
}


#pragma mark Window Overrides

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
	return (_disableConstrainedWindow ? frameRect : [super constrainFrameRect:frameRect toScreen:screen]);
}



#pragma mark Convenince Window Methods

- (void)orderOutWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timing animations:(void (^)(CALayer *))animations {
	[self setupIfNeeded];
	
	// The fake window is in the exact same position as the real one, so we can safely order ourself out.
	[super orderOut:nil];
	[self performAnimations:animations withDuration:duration timing:timing];
}

- (void)makeKeyAndOrderFrontWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timing
								   setup:(void (^)(CALayer *))setup animations:(void (^)(CALayer *))animations {
	[self setupIfNeededWithSetupBlock:setup];
	
	// Avoid unnessesary layout passes if we're already visible when this method is called. This could take place if the window
	// is still being animated out, but the user suddenly changes their mind and the window needs to come back on screen again.
	if (!self.isVisible)
		[super makeKeyAndOrderFront:nil];
	
	[self performAnimations:animations withDuration:duration timing:timing];
}

- (void)setFrame:(NSRect)frameRect withDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timing {
	[self setupIfNeeded];
	
	[super setFrame:frameRect display:YES animate:NO];
	
	NSImage *finalState = [self imageRepresentationOffscreen:YES];
	
	[self performAnimations:^(CALayer *layer) {
		self.windowRepresentationLayer.frame = frameRect;
		self.windowRepresentationLayer.contents = finalState;
	} withDuration:duration timing:timing];
}

- (void)performAnimations:(void (^)(CALayer *layer))animations withDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timing {
	[NSAnimationContext beginGrouping];
	
	[CATransaction begin];
	[CATransaction setAnimationDuration:duration];
	[CATransaction setAnimationTimingFunction:timing?:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[CATransaction setCompletionBlock:^{
		JNWAnimatableWindowOpenTransactions--;
		
		// If there are zero pending operations remaining, we can safely assume that it is time for the window to be destroyed.
		if (JNWAnimatableWindowOpenTransactions == 0) {
			[self destroyTransformingWindow];
		}
	}];
	
	animations(self.windowRepresentationLayer);
	JNWAnimatableWindowOpenTransactions++;
	
	[CATransaction commit];
	[NSAnimationContext endGrouping];
}



#pragma mark Lifecycle

// Called when the ordering methods are complete. If the layer is used
// manually, this should be called when animations are complete.
- (void)destroyTransformingWindow {	
	self.alphaValue = 1.f;
	
	[self.windowRepresentationLayer removeFromSuperlayer];
	self.windowRepresentationLayer.contents = nil;
	self.windowRepresentationLayer = nil;
	
	[self.fullScreenWindow orderOut:nil];
	self.fullScreenWindow = nil;
}

@end

@implementation JNWAnimatableWindowContentView

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	
	// Make the content view a layer-hosting view, so we can safely add sublayers instead of subviews.
	self.layer = [CALayer layer];
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
	
	return self;
}

@end
