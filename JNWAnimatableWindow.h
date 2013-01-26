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
// while a transform is applied.
@interface JNWAnimatableWindow : NSWindow

// This layer can be transformed as much as desired. As soon as the property is first used,
// an image representation of the current window's state will be grabbed and used for the layer.
//
// The downside of using a static image is that it will not reflect the state of the window
// if it changes. If the window needs to change content while still having a transformed state,
// call -updateImageRepresentation to update the backing image.
@property (nonatomic, assign, readonly) CALayer *layer;

// Used to update the graphical representation of the window when a transform is applied.
- (void)updateImageRepresentation;

// Destroys the layer and fake window.
- (void)destroyTransformingWindow;

// Keeps the real window hidden, and wraps an implicit transaction around the `animations` block. The layer of the window
// can be safely animated during this time. The window is automatically destroyed after the animation is complete.
- (void)orderOutWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction
				  animations:(void (^)(CALayer *layer))animations;

- (void)makeKeyAndOrderFrontWithDuration:(CFTimeInterval)duration timing:(CAMediaTimingFunction *)timingFunction
								   setup:(void (^)(CALayer *layer))setup animations:(void (^)(CALayer *layer))animations;

@end
