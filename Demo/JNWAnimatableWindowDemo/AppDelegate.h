//
//  AppDelegate.h
//  JNWAnimatableWindowDemo
//
//  Created by Jonathan Willing on 1/25/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

@import Cocoa;
@import QuartzCore;
#import "JNWAnimatableWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, CAAnimationDelegate>

@property (assign) IBOutlet JNWAnimatableWindow *window;

- (IBAction)moveAround:(id)sender;
- (IBAction)animateOut:(id)sender;
- (IBAction)animateFrame:(id)sender;

- (IBAction)animateOutExplicitly:(id)sender;

@end
