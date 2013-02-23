//
//  AppDelegate.h
//  JNWAnimatableWindowDemo
//
//  Created by Jonathan Willing on 1/25/13.
//  Copyright (c) 2013 AppJon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JNWAnimatableWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet JNWAnimatableWindow *window;

- (IBAction)moveAround:(id)sender;
- (IBAction)animateOut:(id)sender;
- (IBAction)animateFrame:(id)sender;

- (IBAction)animateOutExplicitly:(id)sender;

@end
