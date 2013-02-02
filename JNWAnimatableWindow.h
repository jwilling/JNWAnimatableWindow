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


#import <Cocoa/Cocoa.h>

// Allows for an extremely flexible manipulation of a static representation of the window.
//
// Since it uses a visual representation of the window, the window cannot be interacted with
// while a transform is applied, nor is it automatically updated to reflect the window's state.
@interface JNWAnimatableWindow : NSWindow

// This layer can be transformed as much as desired. As soon as the property is first used an image
// representation of the current window's state will be grabbed and used for the layer's contents.
//
// Because it is a static image, it will not reflect the state of the window if it changes.
// If the window needs to change content while still having a transformed state,
// call `-updateImageRepresentation` to update the backing image.
@property (nonatomic, assign, readonly) CALayer *layer;

// Destroys the layer and fake window. Only nessesary for use if the layer is animated manually.
// If the convenience methods are used below, calling this is not nessesary as it is done automatically.
- (void)destroyTransformingWindow;

// Order a window out with an animation. The `animations` block is wrapped in a `CATransaction`, so implicit
// animations will be enabled. Pass in nil for the timing function to default to ease-in-out.
//
// The layer and the extra window will be destroyed automatically after the animation completes.
- (void)orderOutWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction
				  animations:(void (^)(CALayer *windowLayer))animations;

// Make a window key and visible with an animation. The setup block will be performed with implicit animations
// disabled, so it is an ideal time to set the initial state for your animation. The `animations` block is wrapped
// in a `CATransaction`, so implicit animations will be enabled. Pass in nil for the timing function to default to ease-in-out.
//
// The layer and the extra window will be destroyed automatically after the animation completes.
- (void)makeKeyAndOrderFrontWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction
								   setup:(void (^)(CALayer *windowLayer))setup animations:(void (^)(CALayer *layer))animations;


// Sets the window to the frame specified using a layer The animation behavoior is the same as
// NSWindow's full-screen animation, which cross-fades between the initial and final state images.
//
// The layer and the extra window will be destroyed automatically after the animation completes.
- (void)setFrame:(NSRect)frameRect withDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timing;

@end
