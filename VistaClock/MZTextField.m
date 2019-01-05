//
//  MZTextField.m
//  VistaClock
//
//  Created by Paul Wong on 1/14/16.
//  Copyright © 2016 Mazookie, LLC. All rights reserved.
//

#import "MZTextField.h"
#import "MZVistaClockAppDelegate.h"

@implementation MZTextField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if (([event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagCommand) {
        if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
            // Map Command-X to Cut
            return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
        }
        else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
            // Map Command-C to Copy
            return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
        }
        else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
            // Map Command-V to Paste
            return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
        }
        else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
            // Map Command-A to Select All
            return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
        }
    }
    return [super performKeyEquivalent:event];
}

- (void)cancelOperation:(id)sender
{
    [(MZVistaClockAppDelegate *)[[NSApplication sharedApplication] delegate] toggleVistaClockWindow:self];
}
@end
