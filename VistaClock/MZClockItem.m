#if !defined(__aarch64__)
#error "This application is supported only on Apple Silicon (arm64)."
#endif

#if defined(__aarch64__)
//
//  MZClockItem.m
//  VistaClock
//
//  Created by Paul Wong on 5/27/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import "MZClockItem.h"

@implementation MZClockItem


-(void) configureClockItem:
    (NSString*) newCaption
    zone:(NSTimeZone*) newZone
    clockFace:(NSString*) newClockFace
    useShadow: (bool) newUseShadow
    largeFonts:(bool) newLargeFonts
    seconds:(bool) newSeconds
    militaryTime:(bool) newMilitaryTime
{
    // Font Shadow
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize( 1, 1 )];
    [shadow setShadowBlurRadius:1.5];
    
    [clockCaption setStringValue:newCaption];
    [clock useWhiteHands:[newClockFace hasPrefix:@"VCW"]];
    [clock setClockFace:newClockFace];

    timezone = newZone;
    useShadow = newUseShadow;
    useLargeFonts = newLargeFonts;
    useSeconds = newSeconds;
    [clock useSecondHand:useSeconds];
    useMilitaryTime = newMilitaryTime;
    
    // use new config values
    if (useShadow)
    {
        // Shadow color
        [shadow setShadowColor:[NSColor shadowColor]];

        [clockCaption setShadow:shadow];
        [time setShadow:shadow];
        [day setShadow:shadow];
    }
    else
    {
        [clockCaption setShadow:NULL];
        [time setShadow:NULL];
        [day setShadow:NULL];
    }

    if (useLargeFonts)
    {
        [clockCaption setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont systemFontSize]+2]];
        [time setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont systemFontSize]+2]];
        [day setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont smallSystemFontSize]+1]];
    }
    else
    {
        [clockCaption setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont systemFontSize]]];
        [time setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont systemFontSize]]];
        [day setFont:[NSFont fontWithName:@"Helvetica Neue" size:[NSFont smallSystemFontSize]]];
    }
    
}


-(void) setUseMilitaryTime:(bool) value
{
    useMilitaryTime = value;
}

-(void) setUseShadow:(bool) value
{
    useShadow = value;
}

-(void) setUseLargeFonts:(bool) value
{
    useLargeFonts = value;
}

-(void) setUseSeconds:(bool) value
{
    useSeconds = value;
    [clock useSecondHand:useSeconds];
}


-(void) setClockFace:(NSString*)newImage
{
    [clock setClockFace:newImage];
}


-(void) setCaption:(NSString*) newCaption
{
    [clockCaption setStringValue:newCaption];
}


-(void) update:(NSDate*) now
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:timezone.name]];
        
    if (useMilitaryTime)
    {
        if (useSeconds)
        {
            dateFormatter.dateFormat = @"HH:mm:ss";
        }
        else
        {
            dateFormatter.dateFormat = @"HH:mm";
        }
    }
    else
    {
        if (useSeconds)
        {
            dateFormatter.dateFormat = @"h:mm:ss a";
        }
        else
        {
            dateFormatter.dateFormat = @"h:mm a";
        }
    }
    
    NSString* shortTimeString = [dateFormatter stringFromDate:now];
        
    dateFormatter.dateFormat = @"EEEE";
    [day setStringValue:[dateFormatter stringFromDate:now]];
        
    NSInteger src = [[NSTimeZone localTimeZone] secondsFromGMTForDate:now];
    NSInteger dest
            = [[NSTimeZone timeZoneWithName:timezone.name]
            secondsFromGMTForDate:now];

    NSTimeInterval interval = dest - src;

    [time setStringValue:shortTimeString];
    NSDate* tempDate = [[NSDate alloc] initWithTimeInterval:interval
            sinceDate:now];
    [clock setTime:tempDate];

} // end of update

-(NSImage*) getImage
{
    return [clock getImage];
} // end of getImage


@end
#endif // defined(__aarch64__)

