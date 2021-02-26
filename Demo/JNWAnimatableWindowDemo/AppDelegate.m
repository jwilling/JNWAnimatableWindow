//
//  AppDelegate.m
//  JNWAnimatableWindowDemo
//
//  Created by Jonathan Willing on 1/25/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import "AppDelegate.h"
@import QuartzCore;

@implementation AppDelegate

#pragma mark Convenience Methods

- (CFTimeInterval)animationDuration {
	// Return a slower time if the shift key is held down, for testing.
	return ((([NSApp currentEvent].modifierFlags & NSShiftKeyMask) == NSShiftKeyMask) ? 5.f : 0.7f);
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	// If we're already visible, no need to animate.
	if (self.window.isVisible)
		return NO;
	
	// If we are full screen, just order the window front instead of trying to animate.
	if ((self.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask) {
		[self.window makeKeyAndOrderFront:nil];
		return NO;
	}
	

	[self.window makeKeyAndOrderFrontWithDuration:self.animationDuration timing:nil setup:^(CALayer *layer) {
		// Anything done in this setup block is performed without any animation.
		// The layer will not be visible during this time so now is our chance to set initial
		// values for opacity, transform, etc.
		layer.transform = CATransform3DMakeTranslation(0.f, -50., 0.f);
		layer.opacity = 0.f;
	} animations:^(CALayer *layer) {
		
		// Now we're actually animating. In order to make the transition as seamless as possible,
		// we want to set the final values to their original states, so that when the fake window
		// is removed there will be no discernible jump to that state.
		//
		// To change the default timing and duration, just wrap the animations in an NSAnimationContext.
		layer.transform = CATransform3DIdentity;
		layer.opacity = 1.f;
	}];
	
	return NO;
}

- (void)animateOut:(id)sender {
	[self.window orderOutWithDuration:self.animationDuration timing:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] animations:^(CALayer *layer) {
		// We can now basically whatever we want with this layer. Everything is already wrapped in a CATransaction so it is animated implicitly.
		// To change the duration and other properties, just modify the current context. It will apply to the animation.
		layer.transform = CATransform3DMakeTranslation(0.f, -50.f, 0.f);
		layer.opacity = 0.f;
	}];
}

- (void)animateOutExplicitly:(id)sender {
	CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.toValue = @0;
	
	CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
	translation.toValue = @(-50.f);
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	group.animations = @[ opacity, translation ];
	group.duration = self.animationDuration;
	
	[self.window orderOutWithAnimation:group];
}

- (void)animateFrame:(id)sender {
	CGRect rect = CGRectInset(self.window.frame, -100, -50);
	[self.window setFrame:rect withDuration:self.animationDuration timing:nil];
}


#pragma mark Manual Animations

// Here is a somewhat more complex example of animating the window's layer property directly.
// Since this isn't wrapped in one of the convenience methods, we are responsible
// for getting rid of the window when we are done.
- (void)moveAround:(id)sender {
	// Apply a perspective transform onto the layer.
	CATransform3D transform = CATransform3DIdentity;
	transform.m34 = -1.f / 700.f;
	self.window.layer.transform = transform;
	
	// Do a barrel roll.
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
	animation.duration = 3.f;
	animation.toValue = @(2*M_PI);
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

	// Set the delegate on the animation so we know when to remove the fake window.
	animation.delegate = self;
	[self.window.layer addAnimation:animation forKey:nil];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	// Animation is done, so lets get back to our real window by destroying the fake one.
	// Note this only needs to happen if we initiate the creation of the layer ourselves by referencing it,
	// otherwise it is automatically destroyed for us, as mentioned above.
	[self.window destroyTransformingWindow];
}

@end
