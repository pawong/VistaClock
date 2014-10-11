//
//  MZClockConfigItem.m
//  VistaClock
//
//  Created by Paul Wong on 5/27/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import "MZClockConfigItem.h"

@implementation MZClockConfigItem

@synthesize titleConfigLabel, timezoneConfigLabel, deleteButton, useSecond;

-(void) setRepresentedObject:(id)object
{
	[super setRepresentedObject:object];
	
	if (object != nil)
    {
        NSDictionary* data	= (NSDictionary*) [self representedObject];
        NSString* newName	= (NSString*)[data valueForKey:@"Name"];
        NSString* newTimezone	= (NSString*)[data valueForKey:@"Timezone"];
        NSString* newSeconds = (NSString*)[data valueForKey:@"Seconds"];
	
        [titleConfigLabel setStringValue:newName];
        [timezoneConfigLabel setStringValue:newTimezone];
        if ([newSeconds compare:@"YES"] == NSOrderedSame)
        {
            useSecond = YES;
        }
        else
        {
            useSecond = NO;
        }
    }
} // end of setRepresentedObject


@end
