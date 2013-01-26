//
//  AppDelegate.m
//  JNWAnimatableWindowDemo
//
//  Created by Jonathan Willing on 1/25/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	if (self.window.isVisible)
		return NO;
	
	if ((self.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask) {
		[self.window makeKeyAndOrderFront:nil];
		return NO;
	}
		
	
	//[self.window makeKeyAndOrderFront:nil];
	[self.window makeKeyAndOrderFrontWithDuration:0.7
										   timing:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
											setup:^(CALayer *layer) {
												// Anything done in this setup block is performed without any animation.
												// The layer will not be visible during this time so now is our chance to set initial
												// values for opacity, transform, etc.
												
												layer.transform = CATransform3DMakeTranslation(0.f, -50., 0.f);
												layer.opacity = 0.f;
											} animations:^(CALayer *layer) {
												// Now we're actually animating. In order to make the transition as seamless as possible,
												// we want to set the final values to their original states, so that when the fake window
												// is removed there will be no discernible jump to that state.
												
												layer.transform = CATransform3DIdentity;
												layer.opacity = 1.f;
											}];
	return NO;
}

- (void)animateOut:(id)sender {
	[self.window orderOutWithDuration:0.7 timing:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] animations:^(CALayer *layer) {
		// We can now basically whatever we want with this layer. Everything is already wrapped in a CATransaction so everything is animated implicitly.
		layer.transform = CATransform3DMakeTranslation(0.f, -50.f, 0.f);
		layer.opacity = 0.f;
	}];
}


- (void)moveAround:(id)sender {
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
	animation.duration = 3.f;
	animation.autoreverses = YES;
	
	CATransform3D transform = CATransform3DMakeRotation(M_PI, 1.f, 0.f, 0.f);
	transform.m34 = -1.f / 300.f;
	
	animation.toValue = [NSValue valueWithCATransform3D:transform];
	animation.delegate = self;
	[self.window.layer addAnimation:animation forKey:nil];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	[self.window destroyTransformingWindow];
}

@end
