//
//  MZClockConfig.m
//  VistaClock
//
//  Created by Paul Wong on 9/24/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import "MZClockConfig.h"

@implementation MZClockConfig

@synthesize title, timezoneName, useSeconds;


-(void) encodeWithCoder:(NSCoder*) encoder
{
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeObject:timezoneName forKey:@"timezone"];
    [encoder encodeBool:useSeconds forKey:@"seconds"];
} // end of encodeWithCoder


-(id) initWithCoder:(NSCoder*) decoder
{
    if (self == [super init])
    {
        title = [decoder decodeObjectForKey:@"title"];
        timezoneName = [decoder decodeObjectForKey:@"timezone"];
        useSeconds = [decoder decodeBoolForKey:@"seconds"];
    }
    
    return self;
} // end of initWithCoder


@end
