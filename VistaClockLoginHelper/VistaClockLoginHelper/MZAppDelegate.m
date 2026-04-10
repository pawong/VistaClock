//
//  MZAppDelegate.m
//  VistaClockLoginHelper
//
//  Created by pwong on 8/10/12.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import "MZAppDelegate.h"

@implementation MZAppDelegate

@synthesize window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running)
    {
        if ([[app bundleIdentifier] isEqualToString:@"com.Mazookie.VistaClock"])
        {
            alreadyRunning = YES;
        }
    }
    
    if (!alreadyRunning)
    {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSArray *p = [path pathComponents];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"VistaClock"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];
        NSURL *appURL = [NSURL fileURLWithPath:newPath];
        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL configuration:config completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to launch app at %@: %@", appURL, error);
            }
        }];
    }
    [NSApp terminate:nil];
}


@end

