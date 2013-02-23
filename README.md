## JNWAnimatableWindow ##
`JNWAnimatableWindow` is a `NSWindow` subclass that adds a `layer` property onto the window, allowing you to animate it as you wish.

![](http://appjon.com/assets/github/JNWAnimatableWindow.gif)

## Getting Started ##

`JNWAnimatableWindow` has provides both a layer property and a set of order out & order front methods to simplify common animations. If you would like to animate the window manually and if the window is already visible, you can just manipulate the `layer` property on the window.

Example of animating a window closing:

``` objc
[self.window orderOutWithDuration:0.7 timing:nil animations:^(CALayer *layer) {
	layer.opacity = 0.f;
}];
```
Opening:

``` objc
[self.window makeKeyAndOrderFrontWithDuration:0.7 timing:nil setup:^(CALayer *layer) {
	// Setup is not animated
	layer.opacity = 0.f;
} animations:^(CALayer *layer) {
	// This is animated
	layer.opacity = 1.f;
}];
```
Frame change:

``` objc
[self.window setFrame:newFrame withDuration:0.7 timing:nil];
```

In the convenience methods, everything is wrapped in an animated `CATransaction`, so you can modify any layer property you wish and it should be implicitly animated. Also note that passing in nil for the timing function will result in a default animation of ease-in-out.

If you would like to add or remove your windows with `CAAnimation`s, you can do so using the following methods:

``` objc
- (void)orderOutWithAnimation:(CAAnimation *)animation;
- (void)makeKeyAndOrderFrontWithAnimation:(CAAnimation *)animation;
```

If you want to just make your windows fly around the screen like a boss on a whim, you can directly use the `layer` property on `JNWAnimatableWindow`. The first time this property is accessed, it will lazily create an image representation of the window and place that into a layer which is then animatable. When you are done with the layer, you are responsible for calling `-destroyTransformingWindow`, which will remove the extra window and release resources. This is not necessary if you use one of the convenience methods listed above.

See the demo for more examples, and see the header files for more complete documentation.

## Limitations ##
Due to the way `NSWindow` works, there are some large limitations with what this library can provide. It works by taking an image representation of the window, and placing it in a layer, which is in an additional non-opaque fullscreen window. As a result of this static representation, if the window updates its contents while the layer is shown, that change will not be reflected in the layer. So as a result, this class is more geared toward short animations that take place during a time where the content is most unlikely to change, such as when the window is opening or closing.


## License ##
`JNWAnimatableWindow` is licensed under the [MIT](http://opensource.org/licenses/MIT) license. See [LICENSE.md](https://github.com/jwilling/JNWAnimatableWindow/blob/master/LICENSE.md).

But really, all I care about is that you put this library to good use. I want to help make OS X development a friendlier place, and this is one of my attempts at doing so. If you use this, *please* make a note on the [**Wiki**](https://github.com/jwilling/JNWAnimatableWindow/wiki/JNWAnimatableWindow-in-use.), or get in touch with me and I'll do it for you.

## Get In Touch ##
You can follow me on Twitter as [@j_willing](http://twitter.com/j_willing), email me at the email listed on my GitHub profile, or read my blog at [jwilling.com](http://www.jwilling.com).
